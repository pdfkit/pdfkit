require 'shellwords'

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
    @options.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options = normalize_options(@options)

    raise NoExecutableError.new unless File.exists?(PDFKit.configuration.wkhtmltopdf)
  end

  def command(path = nil)
    args = [executable]
    args += @options.to_a.flatten.compact
    args << '--quiet'

    if @source.html?
      args << '-' # Get HTML from stdin
    else
      args << @source.to_s
    end

    args << (path || '-') # Write to file or stdout

    args.shelljoin
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
      pdf.gets(nil)
    end
    status = $? # $? is thread safe per http://stackoverflow.com/questions/2164887/thread-safe-external-process-in-ruby-plus-checking-exitstatus
    result = File.read(path) if path

    raise "command failed (exitstatus=#{status.exitstatus}): #{invoke}" unless successful?(result, status)
    return result
  end

  def to_file(path)
    self.to_pdf(path)
    File.new(path)
  end

  protected

    def find_options_in_meta(content)
      # Read file if content is a File
      content = content.read if content.is_a?(File)

      found = {}
      content.scan(/<meta [^>]*>/) do |meta|
        if meta.match(/name=["']#{PDFKit.configuration.meta_tag_prefix}/)
          name = meta.scan(/name=["']#{PDFKit.configuration.meta_tag_prefix}([^"']*)/)[0][0]
          found[name.to_sym] = meta.scan(/content=["']([^"']*)/)[0][0]
        end
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
        normalized_key = "--#{normalize_arg key}"
        normalized_options[normalized_key] = normalize_value(value)
      end
      normalized_options
    end

    def normalize_arg(arg)
      arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
    end

    def normalize_value(value)
      case value
      when TrueClass #ie, ==true, see http://www.ruby-doc.org/core-1.9.3/TrueClass.html
        nil
      when Hash
        value.to_a.flatten.collect{|x| x.to_s}
      when Array
        value.flatten.collect{|x| x.to_s}
      else
        value.to_s
      end
    end

    def successful?(result, status_info)
      result.to_s.strip.empty? or successful_exit_statuses.include?(status_info.exitstatus)
    end

    def successful_exit_statuses
      # Some of the codes: https://code.google.com/p/wkhtmltopdf/issues/detail?id=1088
      [
        0, # all good
        2 # returned when assets are missing (404): https://code.google.com/p/wkhtmltopdf/issues/detail?id=548
      ]
    end

end
