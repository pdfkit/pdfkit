class PDFKit
  class Configuration
    attr_accessor :meta_tag_prefix, :wkhtmltopdf, :default_options_wkhtmltopdf, :wkhtmltoimage, :default_options_wkhtmltoimage

    def initialize
      @meta_tag_prefix = 'pdfkit-'
      @wkhtmltopdf   = '/usr/local/bin/wkhtmltopdf'
      @default_options_wkhtmltopdf = {
        :disable_smart_shrinking => true,
        :page_size => 'Letter',
        :margin_top => '0.75in',
        :margin_right => '0.75in',
        :margin_bottom => '0.75in',
        :margin_left => '0.75in',
        :encoding => "UTF-8"
      }
      @wkhtmltoimage = '/usr/local/bin/wkhtmltoimage'
      @default_options_wkhtmltoimage = {
      }
    end
  end

  class << self
    attr_accessor :configuration
  end

  # Configure PDFKit someplace sensible,
  # like config/initializers/pdfkit.rb
  #
  # @example
  #   PDFKit.configure do |config|
  #     config.wkhtmltopdf = '/usr/bin/wkhtmltopdf'
  #   end
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  
  def self.configure
    self.configuration 
    yield(configuration)
  end
end
