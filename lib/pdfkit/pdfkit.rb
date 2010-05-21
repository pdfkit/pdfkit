class PDFKit
  
  class NoExecutableError < StandardError
    def initialize
      super('Could not locate wkhtmltopdf executable')
    end
  end
  
  attr_accessor :html, :stylesheets
  attr_reader :options
  
  def initialize(html, options = {})
    @html = html
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
    
    @cmd  = `which wkhtmltopdf`.chomp
    raise NoExecutableError.new if @cmd.blank?
  end
  
  def command
    args = [@cmd]
    args += @options.to_a.flatten.compact
    args << '--quiet'
    args << '-' # Get HTML from stdin
    args << '-' # Read PDF from stdout
    args.join(' ')
  end
  
  def to_pdf
    append_stylesheets
    
    pdf = IO.popen(command, "w+")
    pdf.puts(@html)
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
      stylesheets.each do |stylesheet|
        if @html.match(/<\/head>/)
          @html.gsub!(/(<\/head>)/, "#{style_tag_for(stylesheet)}$1")
        else
          @html.insert(0, style_tag_for(stylesheet))
        end
      end
    end
  
    def normalize_options(options)
      normalized_options = {}
      options.each do |key, value|
        normalized_key = "--#{key.to_s.downcase.dasherize}"
        normalized_value = value.is_a?(TrueClass) ? nil : value
        normalized_options[normalized_key] = normalized_value
      end
      normalized_options
    end
  
end