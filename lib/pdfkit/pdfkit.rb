# frozen_string_literal: true

require 'childprocess'
require 'shellwords'
require 'tempfile'

class PDFKit
  class Error < StandardError; end

  class NoExecutableError < Error
    def initialize
      msg = "No wkhtmltopdf executable found at #{PDFKit.configuration.wkhtmltopdf}\n" \
            ">> Please install wkhtmltopdf - https://github.com/pdfkit/PDFKit/wiki/Installing-WKHTMLTOPDF"
      super(msg)
    end
  end

  class ImproperSourceError < Error
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  class ImproperWkhtmltopdfExitStatus < Error
    def initialize(invoke)
      super("Command failed (exitstatus=#{$?.exitstatus}): #{invoke}")
    end
  end

  class TimeoutError < Error
    def initialize(timeout)
      super("Command timed out after #{timeout} seconds")
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

    raise NoExecutableError unless File.exist?(PDFKit.configuration.wkhtmltopdf)
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

  # TODO(ivy): Set a default `timeout` in the next major version.
  def to_pdf(path=nil, timeout: nil)
    preprocess_html
    append_stylesheets

    invoke = command(path)

    out_reader, out_writer = IO.pipe

    process = ChildProcess.build('/bin/sh', '-c', invoke).tap do |p|
      p.io.stdout = p.io.stderr = out_writer
      p.duplex = true

      p.start

      p.io.stdin.puts(@source.to_s) if @source.html?
      p.io.stdin.close
    end

    begin
      if timeout
        process.poll_for_exit(timeout)
      else
        process.wait
      end
    rescue ChildProcess::TimeoutError
      process.stop
      raise TimeoutError, timeout
    end

    out_writer.close
    result = path.nil? ? out_reader.gets(nil) : nil

    unless process.exit_code.zero? || empty_result?(path, result)
      raise ImproperWkhtmltopdfExitStatus, invoke
    end

    result
  ensure
    process.kill if process&.alive?
    [out_reader, out_writer].compact.each(&:close)
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
    style = "<style>#{File.read(stylesheet)}</style>"
    style = style.html_safe if style.respond_to?(:html_safe)
    style
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
        @source = Source.new(@source.to_s.gsub(/(<\/head>)/) {|s|
          style_tag_for(stylesheet) + (s.respond_to?(:html_safe) ? s.html_safe : s)
        })
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
