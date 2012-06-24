require 'spec_helper'

describe PDFKit::Generator do
  let(:pdfkit_generator_class)  {PDFKit::Generator}
  let(:pdfkit_generator)        {PDFKit.generator}
  let(:pdfkit_configurations)   {PDFKit.configuration.default_options}
  before :all do
    @default_dir_path = File.join 'documents'
    @tmp_dir_path     = File.join 'pdfkit'
    @cover_path       = File.join @tmp_dir_path, 'cover_support_file.html'
    @header_path      = File.join @tmp_dir_path, 'header_support_file.html'
    @footer_path      = File.join @tmp_dir_path, 'footer_support_file.html'
  end
  describe "#default_directory_path" do
    before(:each) do # because we are testing class methods with cache ;)
        PDFKit.send(:remove_const, 'Generator')
        load './lib/pdfkit/generator.rb'
    end
    it "should return the default directory path" do
      pdfkit_generator_class.send(:default_directory_path).should == @default_dir_path
    end
    it "should return the path from PDFKit configurations in initializer" do
      _pdfkit_configuration_default_path = File.join('documents2')
      pdfkit_configurations.stub!(:[], :default_directory_path).and_return(_pdfkit_configuration_default_path)
      # cant use subject because method was called in a previous test and so cache is set
      pdfkit_generator_class.default_directory_path.should == _pdfkit_configuration_default_path
    end
    it "should cache the path used by pdf" do
      File.should_receive(:join).once.with('documents').and_return(@default_dir_path)
      pdfkit_generator_class.send(:default_directory_path).should == @default_dir_path
      # second call to test cache
      pdfkit_generator_class.send(:default_directory_path).should == @default_dir_path
    end
  end
end