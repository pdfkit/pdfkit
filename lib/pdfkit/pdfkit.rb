require 'shellwords'
require 'rbconfig'

class PDFKit
  class NoExecutableError < StandardError
    def initialize
      msg  = "No wkhtmltopdf executable found at #{PDFKit.configuration.wkhtmltopdf}\n"
      msg << ">> Please install wkhtmltopdf - https://github.com/pdfkit/PDFKit/wiki/Installing-WKHTMLTOPDF"
      super(msg)
    end
  end

  class ImproperSourceError < StandardError
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  attr_accessor :source, :stylesheets
  attr_reader :options

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)

    @stylesheets = []

    @options = PDFKit.configuration.default_options.merge(options)
    @options.delete(:quiet) if PDFKit.configuration.verbose?
    @options.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options = normalize_options(@options)

    raise NoExecutableError.new unless File.exists?(PDFKit.configuration.wkhtmltopdf)
  end

  def command(path = nil)
    args = @options.to_a.flatten.compact
    shell_escaped_command = [executable, shell_escape_for_os(args)].join ' '

    # In order to allow for URL parameters (e.g. https://www.google.com/search?q=pdfkit) we do
    # not escape the source. The user is responsible for ensuring that no vulnerabilities exist
    # in the source. Please see https://github.com/pdfkit/pdfkit/issues/164.
    input_for_command = @source.to_input_for_command
    output_for_command = path ? Shellwords.shellescape(path) : '-'

    "#{shell_escaped_command} #{input_for_command} #{output_for_command}"
  end

  def executable
    default = PDFKit.configuration.wkhtmltopdf
    return default if default !~ /^\// # its not a path, so nothing we can do
    if File.exist?(default)
      default
    else
      default.split('/').last
    end
  end

  def to_pdf(path=nil)
    append_stylesheets

    invoke = command(path)

    result = IO.popen(invoke, "wb+") do |pdf|
      pdf.puts(@source.to_s) if @source.html?
      pdf.close_write
      pdf.gets(nil) if path.nil?
    end

    # $? is thread safe per
    # http://stackoverflow.com/questions/2164887/thread-safe-external-process-in-ruby-plus-checking-exitstatus
    raise "command failed (exitstatus=#{$?.exitstatus}): #{invoke}" if empty_result?(path, result) or !successful?($?)
    return result
  end

  def to_file(path)
    self.to_pdf(path)
    File.new(path)
  end

  protected

  # Pulled from:
  # https://github.com/wkhtmltopdf/wkhtmltopdf/blob/ebf9b6cfc4c58a31349fb94c568b254fac37b3d3/README_WKHTMLTOIMAGE#L27
  REPEATABLE_OPTIONS = %w[--allow --cookie --custom-header --post --post-file --run-script]
  SPECIAL_OPTIONS = %w[cover toc]

  def find_options_in_meta(content)
    # Read file if content is a File
    content = content.read if content.is_a?(File)

    found = {}
    content.scan(/<meta [^>]*>/) do |meta|
      if meta.match(/name=["']#{PDFKit.configuration.meta_tag_prefix}/)
        name = meta.scan(/name=["']#{PDFKit.configuration.meta_tag_prefix}([^"']*)/)[0][0].split
        found[name] = meta.scan(/content=["']([^"'\\]+)["']/)[0][0]
      end
    end

    tuple_keys = found.keys.select { |k| k.is_a? Array }
    tuple_keys.each do |key|
      value = found.delete key
      new_key = key.shift
      found[new_key] ||= {}
      found[new_key][key] = value
    end

    found
  end

  def style_tag_for(stylesheet)
    "<style>#{File.read(stylesheet)}</style>"
  end

  def append_stylesheets
    raise ImproperSourceError.new('Stylesheets may only be added to an HTML source') if stylesheets.any? && !@source.html?

    stylesheets.each do |stylesheet|
      if @source.to_s.match(/<\/head>/)
        @source = Source.new(@source.to_s.gsub(/(<\/head>)/) {|s| style_tag_for(stylesheet) + s })
      else
        @source.to_s.insert(0, style_tag_for(stylesheet))
      end
    end
  end

  def normalize_options(options)
    normalized_options = {}

    options.each do |key, value|
      next if !value

      # The actual option for wkhtmltopdf
      normalized_key = normalize_arg key
      normalized_key = "--#{normalized_key}" unless SPECIAL_OPTIONS.include?(normalized_key)

      # If the option is repeatable, attempt to normalize all values
      if REPEATABLE_OPTIONS.include? normalized_key
        normalize_repeatable_value(normalized_key, value) do |normalized_unique_key, normalized_value|
          normalized_options[normalized_unique_key] = normalized_value
        end
      else # Otherwise, just normalize it like usual
        normalized_options[normalized_key] = normalize_value(value)
      end
    end

    normalized_options
  end

  def normalize_arg(arg)
    arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
  end

  def normalize_value(value)
    case value
    when nil
      nil
    when TrueClass, 'true' #ie, ==true, see http://www.ruby-doc.org/core-1.9.3/TrueClass.html
      nil
    when Hash
      value.to_a.flatten.collect{|x| normalize_value(x)}.compact
    when Array
      value.flatten.collect{|x| x.to_s}
    else
      (host_is_windows? && value.to_s.index(' ')) ? "'#{ value.to_s }'" : value.to_s
    end
  end

  def normalize_repeatable_value(option_name, value)
    case value
    when Hash, Array
      value.each do |(key, val)|
        yield [[option_name, normalize_value(key)], normalize_value(val)]
      end
    else
      yield [[option_name, normalize_value(value)], nil]
    end
  end

  def successful?(status)
    return true if status.success?

    # Some of the codes: https://code.google.com/p/wkhtmltopdf/issues/detail?id=1088
    # returned when assets are missing (404): https://code.google.com/p/wkhtmltopdf/issues/detail?id=548
    return true if status.exitstatus == 2 && error_handling?

    false
  end

  def empty_result?(path, result)
    (path && File.size(path) == 0) || (path.nil? && result.to_s.strip.empty?)
  end

  def error_handling?
    @options.key?('--ignore-load-errors') ||
      # wkhtmltopdf v0.10.0 beta4 replaces ignore-load-errors with load-error-handling
      # https://code.google.com/p/wkhtmltopdf/issues/detail?id=55
      %w(skip ignore).include?(@options['--load-error-handling'])
  end

  def host_is_windows?
    @host_is_windows ||= !(RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince/).nil?
  end

  def shell_escape_for_os(args)
    if (host_is_windows?)
      # Windows reserved shell characters are: & | ( ) < > ^
      # See http://technet.microsoft.com/en-us/library/cc723564.aspx#XSLTsection123121120120
      args.map { |arg| arg.gsub(/([&|()<>^])/,'^\1') }.join(" ")
    else
      args.shelljoin
    end
  end
end
