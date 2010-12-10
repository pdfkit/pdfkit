SPEC_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(SPEC_ROOT)
$LOAD_PATH.unshift(File.join(SPEC_ROOT, '..', 'lib'))
require 'pdfkit'
require 'rspec'
require 'rspec/autorun'
require 'mocha'
require 'rack'
require 'custom_wkhtmltopdf_path' if File.exists?(File.join(SPEC_ROOT, 'custom_wkhtmltopdf_path.rb'))

RSpec.configure do |config|
  
  config.before do
    PDFKit.any_instance.stubs(:wkhtmltopdf).returns(
      File.join(SPEC_ROOT,'..','bin','wkhtmltopdf-proxy')
    )
  end
  
end
