class PDFKit

  class NoExecutableError < StandardError
  end
  class UnknownFormatError < StandardError
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
    @options_wkhtmltopdf   = PDFKit.configuration.default_options_wkhtmltopdf.merge(options)
    @options_wkhtmltopdf.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options_wkhtmltopdf = normalize_options(@options_wkhtmltopdf)
    
    # wkhtmltoimage options
    @options_wkhtmltoimage   = PDFKit.configuration.default_options_wkhtmltoimage.merge(options)
    @options_wkhtmltoimage.merge! find_options_in_meta(url_file_or_html) unless source.url?
    @options_wkhtmltoimage = normalize_options(@options_wkhtmltoimage)
    
    # Check for executables
    ['wkhtmltopdf','wkhtmltoimage'].each do |binary|
      unless File.exists?(PDFKit.configuration.method(binary).call) then
        msg  = "No #{binary} executable found at #{PDFKit.configuration.method(binary).call}\n"
        msg << ">> Install #{binary} by hand or try running `pdfkit --install-#{binary}`"
        raise NoExecutableError.new(msg)
      end
    end

  end
  
  def command(format)
    args = [executable(format)]
    case binary_name(format)
      when 'wkhtmltopdf' then
        args += @options_wkhtmltopdf.to_a.flatten.compact
        args << '--quiet'
      when 'wkhtmltoimage' then
        args += @options_wkhtmltoimage.to_a.flatten.compact
    end
    

    if @source.html?
      args << '-' # Get HTML from stdin
    else
      args << @source.to_s
    end
    
    args << '-' # Read PDF from stdout
#puts args.join(" ")
    args
  end

  def executable(format)
    default = PDFKit.configuration.method( binary_name(format) ).call
    return default if default !~ /^\// # its not a path, so nothing we can do
    if File.exist?(default)
      default
    else
      default.split('/').last
    end
  end
  
  def binary_name(format)
    case format
      when 'pdf' then
        return 'wkhtmltopdf'
      when /jpg|png|gif/ then
        return 'wkhtmltoimage'
      else
        raise UnknownFormatError.new("Unknown format: #{format}\nValid formats are: pdf, jpg, png, gif")
    end
  end

  def to_pdf
    append_stylesheets
    
    pdf = Kernel.open('|-', "w+")
    exec(*command('pdf')) if pdf.nil?
    pdf.puts(@source.to_s) if @source.html?
    pdf.close_write
    result = pdf.gets(nil)
    pdf.close_read

    raise "command failed: #{command('pdf').join(' ')}" if result.to_s.strip.empty?
    return result
  end
  
  def to_image(format='png')
    options_wkhtmltoimage['--format'] = format
    append_stylesheets

    img = Kernel.open('|-', "w+")
    exec(*command(format)) if img.nil?
    img.puts(@source.to_s) if @source.html?
    img.close_write
    result = img.gets(nil)
    img.close_read

    raise "command failed: #{command(format).join(' ')}" if result.to_s.strip.empty?
    return result
  end

  ['jpg','png','gif'].each do |type|
    define_method("to_#{type}".to_sym) do |*params|
      to_image(type)
    end
  end


  def to_file(path, format='pdf')
    conversion_method = self.method( "to_#{format}" )
    File.open(path,'w') {|file| file << conversion_method.call}
  end
  
  protected

    def find_options_in_meta(body)
      pdfkit_meta_tags(body).inject({}) do |found, tag|
        name = tag.attributes["name"].sub(/^#{PDFKit.configuration.meta_tag_prefix}/, '').to_sym
        found.merge(name => tag.attributes["content"])
      end
    end

    def pdfkit_meta_tags(body)
      require 'rexml/document'
      xml_body = REXML::Document.new(body)
      found = []
      xml_body.elements.each("html/head/meta") do |tag|
        found << tag if tag.attributes['name'].to_s =~ /^#{PDFKit.configuration.meta_tag_prefix}/
      end
      found
    rescue # rexml random crash on invalid xml
      []
    end
  
    def style_tag_for(stylesheet)
      "<style>#{File.read(stylesheet)}</style>"
    end
    
    def append_stylesheets
      raise ImproperSourceError.new('Stylesheets may only be added to an HTML source') if stylesheets.any? && !@source.html?
      
      stylesheets.each do |stylesheet|
        if @source.to_s.match(/<\/head>/)
          @source.to_s.gsub!(/(<\/head>)/, style_tag_for(stylesheet)+'\1')
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
