class PDFKit

  class NoExecutableError < StandardError
    def initialize
      msg  = "No wkhtmltopdf executable found at #{PDFKit.configuration.wkhtmltopdf}\n"
      msg << ">> Please install wkhtmltopdf - https://github.com/jdpace/PDFKit/wiki/Installing-WKHTMLTOPDF"
      super(msg)
    end
  end

  class ImproperSourceError < StandardError
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  attr_accessor :source, :stylesheets
  attr_reader :options, :toc_options, :cover_options

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)

    @stylesheets = []

    @toc_options   = options.delete(:toc_options) || { }
    @cover_options = options.delete(:cover_options) || { }

    @options = PDFKit.configuration.default_options.merge(options)
    @toc_options   = PDFKit.configuration.toc_options.merge(@toc_options)
    @cover_options = PDFKit.configuration.cover_options.merge(@cover_options)
    @options.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options = normalize_options(@options)
    @toc_options = normalize_options(@toc_options)
    @cover_options = normalize_options(@cover_options)

    raise NoExecutableError.new unless File.exists?(PDFKit.configuration.wkhtmltopdf)
  end

  def command(path = nil)
    args = [executable]
    args += @options.to_a.flatten.compact
    args << '--quiet'
    args += build_special_options('cover', cover_options, [:file])
    args += build_special_options('toc', toc_options)

    if @source.html?
      args << '-' # Get HTML from stdin
    else
      args << @source.to_s
    end

    args << (path || '-') # Write to file or stdout

    args.map {|arg| "\"#{arg.gsub('"', '\\"')}\"" }
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

    args = command(path)
    invoke = args.join(' ')

    result = IO.popen(invoke, "wb+") do |pdf|
      pdf.puts(@source.to_s) if @source.html?
      pdf.close_write
      pdf.gets(nil)
    end
    result = File.read(path) if path

    raise "command failed: #{invoke}" if result.to_s.strip.empty?
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
          @source = Source.new(@source.to_s.gsub(/(<\/head>)/, style_tag_for(stylesheet)+'\1'))
        else
          @source.to_s.insert(0, style_tag_for(stylesheet))
        end
      end
    end

    def build_special_options(option_type, options, option_without_name = [])
      if options.length > 0
        args = [option_type]
        plain_options = option_without_name.map { |option| options["--#{normalize_arg(option)}"] }

        args += plain_options
        args += options.select { |arg, value| option_without_name.find { |opt| opt != arg }.nil? }.flatten
        args
      else
        []
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
      when TrueClass
        nil
      else
        value.to_s
      end
    end

end
