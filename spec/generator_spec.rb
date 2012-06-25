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
  # clean cache
  def clean_cache
    PDFKit.send(:remove_const, 'Generator')
    load './lib/pdfkit/generator.rb'
  end
  # precondition methods assurance
  def directories_up_precondition
    FileUtils.mkdir_p(@tmp_dir_path)
    File.directory?(@tmp_dir_path).should be_true
    FileUtils.mkdir_p(@default_dir_path)
    File.directory?(@default_dir_path).should be_true
  end
  def directories_down_precondition
    FileUtils.rm_rf(@default_dir_path)
    File.directory?(@default_dir_path).should be_false
    FileUtils.rm_rf(@tmp_dir_path)
    File.directory?(@tmp_dir_path).should be_false
  end
  def files_up_precondition
    File.exists?(@cover_path).should be_true
    File.exists?(@header_path).should be_true
    File.exists?(@footer_path).should be_true
  end
  describe "#default_directory_path" do
    before(:each) do # because we are testing class methods with cache ;)
      clean_cache
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
  describe "#default_directory_creation" do
    it "should create the directory used by pdfkit to create the support files" do
      # precondition
      directories_down_precondition

      pdfkit_generator_class.send(:default_directory_creation)
      File.directory?(@default_dir_path).should be_true

      # remove creted directory
      directories_down_precondition
    end
  end
  describe "#pdf_kit_temporary_directory_path" do
    before(:each) do # because we are testing class methods with cache ;)
      clean_cache
    end
    it "should return the path used by pdfkit to create the support files" do
      pdfkit_generator_class.send(:temporary_directory_path).should == @tmp_dir_path
    end
    it "should return the path from PDFKit configurations in initializer" do
      _pdfkit_configuration_default_path = File.join('pdfkit2')
      pdfkit_configurations.stub!(:[]).with(:support_directory_path).and_return(_pdfkit_configuration_default_path)
      # cant use subject because method was called in a previous test and so cache is set
      pdfkit_generator_class.send(:temporary_directory_path).should == _pdfkit_configuration_default_path
    end
    it "should cache the path used by pdfkit to create the support files" do
      File.should_receive(:join).once.with('pdfkit').and_return(@tmp_dir_path)
      pdfkit_generator_class.send(:temporary_directory_path).should == @tmp_dir_path
      # second call to test cache
      pdfkit_generator_class.send(:temporary_directory_path).should == @tmp_dir_path
    end
  end
  describe "#pdf_kit_temporary_directory_creation" do
    it "should create the directory used by pdfkit to create the support files" do
      # precondition
      directories_down_precondition

      pdfkit_generator_class.send(:temporary_directory_creation)
      File.directory?(@tmp_dir_path).should be_true
    end
  end
  describe "#temporary_directory_deletion" do
    it "should delete the directory used by pdfkit to create the support files" do
      # precondition
      directories_up_precondition

      pdfkit_generator_class.send(:temporary_directory_deletion)
      File.directory?(@tmp_dir_path).should be_false
    end
  end
  describe "#temporary_files_path" do
    before(:each) do # because we are testing class methods with cache ;)
      clean_cache
    end
    it "should return the temporary files path" do
      # cant use subject because method was called in a previous test and so cache is set
      pdfkit_generator_class.send(:temporary_file_paths).should == {:cover => @cover_path, :header => @header_path, :footer => @footer_path}
    end
    it "should return the cached support file paths" do
      pdfkit_generator_class.should_receive(:temporary_directory_path).exactly(3).times.and_return(@tmp_dir_path)

      pdfkit_generator_class.send(:temporary_file_paths)
      # second call to test cache
      pdfkit_generator_class.send(:temporary_file_paths)
    end
  end
  describe "#temporary_files_creation" do
    it "should create the temporary files to support pdf kit" do
      # precondition
      directories_down_precondition

      pdfkit_generator_class.send(:temporary_files_creation)

      %W{cover_support_file.html header_support_file.html footer_support_file.html}.each do |file_name|
        File.exists?(File.join(@tmp_dir_path,file_name)).should be_true
      end
    end
  end
  describe "#pdf_kit_temporary_files_injection" do
    it "should inject the stream content into the support files" do
      # precondition
      pdfkit_generator_class.send(:temporary_files_creation)

      _cover_content  = "<p>COVER:  CODE SHOULD BE REUSABLE...ALWAYS :D!</p><p>I have said that many times.</p>"
      _header_content = "<p>HEADER: CODE SHOULD BE REUSABLE...ALWAYS :D!</p><p>I have said that many times.</p>"
      _footer_content = "<p>FOOTER: CODE SHOULD BE REUSABLE...ALWAYS :D!</p><p>I have said that many times.</p>"

      pdfkit_generator_class.send(:temporary_files_injection, _cover_content, _header_content, _footer_content)

      File.read(@cover_path).should  == _cover_content
      File.read(@header_path).should == _header_content
      File.read(@footer_path).should == _footer_content
    end
  end
  describe "#temporary_files_deletion" do
    it "should delete the temporary support files created" do
      # precondition
      pdfkit_generator_class.send(:temporary_files_creation)
      files_up_precondition

      # delete files
      pdfkit_generator_class.send(:temporary_files_deletion)
      # they should not exist
      File.exists?(@cover_path).should be_false
      File.exists?(@header_path).should be_false
      File.exists?(@footer_path).should be_false
    end
  end
end