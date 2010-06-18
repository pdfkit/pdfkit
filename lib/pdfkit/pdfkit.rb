class PDFKit
  
  class NoExecutableError < StandardError
    def initialize
      super('Could not locate wkhtmltopdf-proxy executable')
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
    
    default_options = {
      :disable_smart_shrinking => true,
      :page_size => 'Letter',
      :margin_top => '0.75in',
      :margin_right => '0.75in',
      :margin_bottom => '0.75in',
      :margin_left => '0.75in'
    }
    @options = normalize_options(default_options.merge(options))
    
    raise NoExecutableError.new if wkhtmltopdf.nil? || wkhtmltopdf == ''
  end
  
  def command
    args = [wkhtmltopdf]
    args += @options.to_a.flatten.compact
    args << '--quiet'
    
    if @source.html?
      args << '-' # Get HTML from stdin
    else
      args << @source.to_s
    end
    
    args << '-' # Read PDF from stdout
    args.join(' ')
  end
  
  def to_pdf
    append_stylesheets
    
    pdf = IO.popen(command, "w+")
    pdf.puts(@source.to_s) if @source.html?
    pdf.close_write
    result = pdf.gets(nil)
    pdf.close_read
    return result
  end
  
  def to_file(path)
    File.open(path,'w') {|file| file << self.to_pdf}
  end
  
  protected
  
    def wkhtmltopdf
      @wkhtmltopdf ||= `which wkhtmltopdf-proxy`.chomp
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
      when String
        value.match(/\s/) ? "\"#{value}\"" : value
      else
        value
      end
    end
  
end