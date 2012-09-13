class PDFKit
  class Configuration
    attr_accessor :meta_tag_prefix, :default_options, :root_url, :toc_options, :cover_options
    attr_writer :wkhtmltopdf

    def initialize
      @meta_tag_prefix = 'pdfkit-'
      @default_options = {
        :disable_smart_shrinking => false,
        :page_size => 'Letter',
        :margin_top => '0.75in',
        :margin_right => '0.75in',
        :margin_bottom => '0.75in',
        :margin_left => '0.75in',
        :encoding => "UTF-8"
      }

      @toc_options   = { }
      @cover_options = { }
    end

    def wkhtmltopdf
      @wkhtmltopdf ||= (defined?(Bundler::GemfileError) ? `bundle exec which wkhtmltopdf` : `which wkhtmltopdf`).chomp
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
    yield(configuration)
  end
end
