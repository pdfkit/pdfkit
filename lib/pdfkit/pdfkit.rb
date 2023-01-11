# frozen_string_literal: true

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
    args = [*executable]
    args.concat(@renderer.options_for_command)
    args << @source.to_input_for_command
    args << (path ? path.to_s : '-')
    args
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

    result = IO.popen(invoke, "wb+") do |pdf|
      pdf.puts(@source.to_s) if @source.html?
      pdf.close_write
      pdf.gets(nil) if path.nil?
    end

    # $? is thread safe per
    # http://stackoverflow.com/questions/2164887/thread-safe-external-process-in-ruby-plus-checking-exitstatus
    raise ImproperWkhtmltopdfExitStatus, invoke if empty_result?(path, result) || !successful?($?)
    return result
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
