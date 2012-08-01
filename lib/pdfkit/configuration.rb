class PDFKit
  class Configuration
    attr_accessor :meta_tag_prefix, :default_options_wkhtmltopdf, :default_options_wkhtmltoimage, :root_url
    attr_writer :wkhtmltopdf, :wkhtmltoimage

    def initialize
      @meta_tag_prefix = 'pdfkit-'
      @default_options_wkhtmltopdf = {
        :disable_smart_shrinking => false,
        :page_size => 'Letter',
        :margin_top => '0.75in',
        :margin_right => '0.75in',
        :margin_bottom => '0.75in',
        :margin_left => '0.75in',
        :encoding => "UTF-8"
      }
      @default_options_wkhtmltoimage = {
      }
    end

    def wkhtmltopdf
      @wkhtmltopdf ||= (defined?(Bundler::GemfileError) ? `bundle exec which wkhtmltopdf` : `which wkhtmltopdf`).chomp
    end

    def wkhtmltoimage
      @wkhtmltoimage ||= (defined?(Bundler::GemfileError) ? `bundle exec which wkhtmltoimage` : `which wkhtmltoimage`).chomp
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
  #     config.wkhtmltopdf   = '/usr/bin/wkhtmltopdf'
  #     config.wkhtmltoimage = '/usr/bin/wkhtmltoimage'
  #   end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
