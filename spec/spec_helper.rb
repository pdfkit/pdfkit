SPEC_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(SPEC_ROOT)
$LOAD_PATH.unshift(File.join(SPEC_ROOT, '..', 'lib'))
require 'simplecov'
SimpleCov.start do
  add_filter 'spec/'
end

require 'pdfkit'
require 'rspec'
require 'mocha'
require 'rack'
require 'rack/test'
require 'active_support'
require 'custom_wkhtmltopdf_path' if File.exists?(File.join(SPEC_ROOT, 'custom_wkhtmltopdf_path.rb'))

RSpec.configure do |config|
  include Rack::Test::Methods
end
