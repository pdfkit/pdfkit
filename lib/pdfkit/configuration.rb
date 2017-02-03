class PDFKit
  class Configuration
    attr_accessor :meta_tag_prefix, :default_options, :root_url
    attr_writer :verbose

    def initialize
      @verbose         = false
      @meta_tag_prefix = 'pdfkit-'
      @default_options = {
        :disable_smart_shrinking => false,
        :quiet => true,
        :page_size => 'Letter',
        :margin_top => '0.75in',
        :margin_right => '0.75in',
        :margin_bottom => '0.75in',
        :margin_left => '0.75in',
        :encoding => 'UTF-8'
      }
    end

    def wkhtmltopdf
      @wkhtmltopdf ||= default_wkhtmltopdf
    end

    def default_wkhtmltopdf
      @default_command_path ||=
        if defined?(Bundler::GemfileError) && File.exists?('Gemfile')
          # Starting with Bundler 1.14, if the Bundler.rubygems.user_home value
          # is a read-only or non-existent directory, Bundler prints out an error message.
          # We want to ignore this message, so we want to find the first line that points
          # to a file
          `bundle exec which wkhtmltopdf`.lines.detect { |l| File.file?(l) }.to_s.chomp
        else
          `which wkhtmltopdf`.chomp
        end
    end

    def wkhtmltopdf=(path)
      if File.exist?(path)
        @wkhtmltopdf = path
      else
        warn "No executable found at #{path}. Will fall back to #{default_wkhtmltopdf}" unless File.exist?(path)
        @wkhtmltopdf = default_wkhtmltopdf
      end
    end

    def quiet?
      !@verbose
    end

    def verbose?
      @verbose
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
  #     config.verbose     = true
  #   end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
