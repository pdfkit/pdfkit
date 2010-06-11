SPEC_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(SPEC_ROOT)
$LOAD_PATH.unshift(File.join(SPEC_ROOT, '..', 'lib'))
require 'pdfkit'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end
