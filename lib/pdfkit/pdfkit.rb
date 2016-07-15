require 'shellwords'
require 'tempfile'
require 'open3'

class PDFKit
  class Error < StandardError; end

  class NoExecutableError < Error
    def initialize
      msg  = "No wkhtmltopdf executable found at #{PDFKit.configuration.wkhtmltopdf}\n"
      msg << ">> Please install wkhtmltopdf - https://github.com/pdfkit/PDFKit/wiki/Installing-WKHTMLTOPDF"
      super(msg)
    end
  end

  class ImproperSourceError < Error
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  class ImproperWkhtmltopdfExitStatus < Error
    def initialize(invoke, err)
      super("Command failed (exitstatus=#{$?.exitstatus}): #{invoke}\n  #{err}")
    end
  end

  attr_accessor :source, :stylesheets
  attr_reader :renderer

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)

    @stylesheets = []

    options = PDFKit.configuration.default_options.merge(options)
    options.delete(:quiet) if PDFKit.configuration.verbose?
    options.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @root_url = options.delete(:root_url)
    @protocol = options.delete(:protocol)
    @renderer = WkHTMLtoPDF.new options
    @renderer.normalize_options

    raise NoExecutableError unless File.exists?(PDFKit.configuration.wkhtmltopdf)
  end

  def command(path = nil)
    args = @renderer.options_for_command
    shell_escaped_command = [executable, OS::shell_escape_for_os(args)].join ' '

    # In order to allow for URL parameters (e.g. https://www.google.com/search?q=pdfkit) we do
    # not escape the source. The user is responsible for ensuring that no vulnerabilities exist
    # in the source. Please see https://github.com/pdfkit/pdfkit/issues/164.
    input_for_command = @source.to_input_for_command
    output_for_command = path ? Shellwords.shellescape(path) : '-'

    "#{shell_escaped_command} #{input_for_command} #{output_for_command}"
  end

  def options
    # TODO(cdwort,sigmavirus24): Replace this with an attr_reader for @renderer instead in 1.0.0
    @renderer.options
  end

  def executable
    PDFKit.configuration.executable
  end

  def to_pdf(path=nil)
    preprocess_html
    append_stylesheets

    invoke = command(path)
    result, err, status = Open3.popen3(invoke) do |i, o, e, t|
      i.binmode
      o.binmode
      e.binmode

      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }
      if @source.html?
        begin
          i.write @source.to_s 
        rescue Errno::EPIPE
        end
      end
      i.close
      if t.join(PDFKit.configuration.timeout)
        [out_reader.value, err_reader.value, t.value]
      else
        Process.kill("TERM", t.pid)
        raise "command timeout after #{PDFKit.configuration.timeout} seconds: #{invoke}"
      end
    end

    if successful?(status) && !empty_result?(path, result)
      result
    else
      raise ImproperWkhtmltopdfExitStatus.new(invoke, err)
    end
  end

  def to_file(path)
    self.to_pdf(path)
    File.new(path)
  end

  protected

  def find_options_in_meta(content)
    # Read file if content is a File
    content = content.read if content.is_a?(File) || content.is_a?(Tempfile)

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

  def preprocess_html
    if @source.html?
      processed_html = PDFKit::HTMLPreprocessor.process(@source.to_s, @root_url, @protocol)
      @source = Source.new(processed_html)
    end
  end

  def append_stylesheets
    raise ImproperSourceError, 'Stylesheets may only be added to an HTML source' if stylesheets.any? && !@source.html?

    stylesheets.each do |stylesheet|
      if @source.to_s.match(/<\/head>/)
        @source = Source.new(@source.to_s.gsub(/(<\/head>)/) {|s| style_tag_for(stylesheet) + s })
      else
        @source.to_s.insert(0, style_tag_for(stylesheet))
      end
    end
  end

  def successful?(status)
    return true if status.success?

    # Some of the codes: https://code.google.com/p/wkhtmltopdf/issues/detail?id=1088
    # returned when assets are missing (404): https://code.google.com/p/wkhtmltopdf/issues/detail?id=548
    return true if status.exitstatus == 2 && @renderer.error_handling?

    false
  end

  def empty_result?(path, result)
    (path && File.size(path) == 0) || (path.nil? && result.to_s.strip.empty?)
  end
end
