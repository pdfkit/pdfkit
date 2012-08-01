class PDFKit

  class NoExecutableError < StandardError
    def initialize(bin)
      msg  = "No #{bin} executable found at #{PDFKit.configuration.send(bin)}\n"
      msg << ">> Please install #{bin} - https://github.com/pdfkit/PDFKit/wiki/Installing-#{bin.to_s.upcase}"
      super(msg)
    end
  end

  class ImproperSourceError < StandardError
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  attr_accessor :source, :stylesheets
  attr_reader :options_wkhtmltopdf, :options_wkhtmltoimage

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)

    @stylesheets = []

    # wkhtmltopdf options
    @options_wkhtmltopdf = PDFKit.configuration.default_options_wkhtmltopdf.merge(options)
    @options_wkhtmltopdf.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options_wkhtmltopdf = normalize_options(@options_wkhtmltopdf)
    raise NoExecutableError.new(:wkhtmltopdf) unless File.exists?(PDFKit.configuration.wkhtmltopdf)

    # wkhtmltoimage options
    @options_wkhtmltoimage = PDFKit.configuration.default_options_wkhtmltoimage.merge(options)
    @options_wkhtmltoimage.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options_wkhtmltoimage = normalize_options(@options_wkhtmltoimage)
    raise NoExecutableError.new(:wkhtmltoimage) unless File.exists?(PDFKit.configuration.wkhtmltoimage)
  end

  def command(format, path = nil)
    args = [executable(format)]
    case binary_name(format)
      when :wkhtmltopdf   then
        args += @options_wkhtmltopdf.to_a.flatten.compact
        args << '--quiet'
      when :wkhtmltoimage then
        args += @options_wkhtmltoimage.to_a.flatten.compact
    end

    if @source.html?
      args << '-' # Get HTML from stdin
    else
      args << @source.to_s
    end

    args << (path || '-') # Write to file or stdout

    args.map {|arg| %Q{"#{arg.gsub('"', '\"')}"}}
  end

  def executable(format)
    default = PDFKit.configuration.send( binary_name(format) )
    return default if default !~ /^\// # its not a path, so nothing we can do
    if File.exist?(default)
      default
    else
      default.split('/').last
    end
  end

  def binary_name(format)
    case format
      when /pdf/         then
        return :wkhtmltopdf
      when /jpg|png|gif/ then
        return :wkhtmltoimage
      else
        raise UnknownFormatError.new("Unknown format: #{format}\nValid formats are: pdf, jpg, png, gif")
    end
  end

  def to_pdf(path=nil)
    append_stylesheets

    args = command('pdf',path)
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

  def to_image(format='png',path=nil)
    options_wkhtmltoimage['--format'] = format
    append_stylesheets

    args = command(format,path)
    invoke = args.join(' ')

    result = IO.popen(invoke, "wb+") do |img|
      img.puts(@source.to_s) if @source.html?
      img.close_write
      img.gets(nil)
    end
    result = File.read(path) if path

    raise "command failed: #{invoke}" if result.to_s.strip.empty?
    return result
  end

  # Image format shortcuts
  ['jpg','png','gif'].each do |format|
    define_method("to_#{format}".to_sym) do |*params|
      to_image(format,*params)
    end
  end

  def to_file(path, format='pdf')
    convert = format.to_s.eql?( 'pdf' ) ? [:to_pdf,path] : [:to_image, format, path]
    self.send(*convert)
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
