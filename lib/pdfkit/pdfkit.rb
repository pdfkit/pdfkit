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
    @options = normalize_options(options.reverse_merge(default_options))
    
    @cmd  = `which wkhtmltopdf-proxy`.chomp
    raise NoExecutableError.new if @cmd.blank?
  end
  
  def command
    args = [@cmd]
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
  
  protected
  
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
        normalized_key = "--#{key.to_s.downcase.dasherize}"
        normalized_value = value.is_a?(TrueClass) ? nil : value
        normalized_options[normalized_key] = normalized_value
      end
      normalized_options
    end
  
end