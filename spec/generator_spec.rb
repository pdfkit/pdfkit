require 'spec_helper'
require 'generator_spec_helper'

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
  after :all do
    delete_default_directory
  end

  context "class methods" do
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
    describe "#pdf_kit_set" do
      context "should set the environment to support pdf kit in generating the pdf document" do
        it "should create the pdf kit temporary directory" do
          # precondition
          directories_down_precondition

          pdfkit_generator_class.send(:set_environment)
          File.directory?(@tmp_dir_path).should be_true
        end
        it "should create the necessary pdf kit temporary files" do
          pdfkit_generator_class.send(:set_environment)
          File.exists?(@cover_path).should be_true
          File.exists?(@header_path).should be_true
          File.exists?(@footer_path).should be_true
        end
      end
    end
    describe "#pdf_kit_unset" do
      context "should unset the environment to support pdf kit in generating the pdf document" do
        it "should delete the pdf kit support files with the pdf kit folder" do
          # precondition
          pdfkit_generator_class.send(:temporary_files_creation)
          File.directory?(@tmp_dir_path).should be_true
          files_up_precondition

          pdfkit_generator_class.send(:unset_environment)
          File.directory?(@tmp_dir_path).should be_false
          File.exists?(@cover_path).should be_false
          File.exists?(@header_path).should be_false
          File.exists?(@footer_path).should be_false
        end
      end
    end
    describe "#options_for_pdf_kit" do
      it "should set the options to pdf kit generate the pdf document out of strings" do
        # set the pdf kit environment
        pdfkit_generator_class.send(:set_environment)

        _project_license_data = {:title => 'the title'}

        _document_parts = {:title => 'the title', :cover => @cover_path.to_s, :header => @header_path.to_s, :footer => @footer_path.to_s}
        _document_configurations = {:outline => true, :'margin-bottom' => 15, :'margin-top' => 15,
                                    :'footer-spacing' => 5, :'header-spacing' => 5}

        _options = pdfkit_generator_class.send(:options_for_pdf_kit, _document_parts, _document_configurations)

        _options[:cover].should             == @cover_path
        _options[:header_html].should       == @header_path
        _options[:footer_html].should       == @footer_path
        _options[:title].should             == 'the title'
        _options[:outline].should be_true
        _options[:'margin-top'].should      == 15
        _options[:'margin-bottom'].should   == 15
        _options[:'header-spacing'].should  == 5
        _options[:'footer-spacing'].should  == 5

        # unset the pdf kit environment
        pdfkit_generator_class.send(:unset_environment)
      end
      it "should set the options to pdf kit generate the pdf document out of html files provided to the method call" do
        _document_parts = {
          :title =>  'the title',
          :cover =>  path_to_document_cover_html_file,
          :header => path_to_document_header_html_file,
          :footer => path_to_document_footer_html_file
        }

        _document_configurations = {:outline => true, :'margin-bottom' => 15, :'margin-top' => 15,
                                    :'footer-spacing' => 5, :'header-spacing' => 5}

        _options = pdfkit_generator_class.send(:options_for_pdf_kit, _document_parts, _document_configurations)

        _options[:cover].should             == path_to_document_cover_html_file
        _options[:header_html].should       == path_to_document_header_html_file
        _options[:footer_html].should       == path_to_document_footer_html_file
        _options[:title].should             == 'the title'
        _options[:outline].should be_true
        _options[:'margin-top'].should      == 15
        _options[:'margin-bottom'].should   == 15
        _options[:'header-spacing'].should  == 5
        _options[:'footer-spacing'].should  == 5
      end
      it "should prefer document configurations passed in method arguments than the ones set in pdfkit default options" do
        PDFKit.configuration.default_options[:page_size].should_not == 'A5'
        _result = pdfkit_generator_class.send(:options_for_pdf_kit, {:title => 'the title'}, {:page_size => 'A5'})

        _result[:page_size].should == 'A5'
        _result[:title].should == 'the title'
      end
      it "should always set cover, header, footer and title according to the configuration set by this module" do
        PDFKit.configuration.stub!(:default_options).and_return({:header_html => 'bad_header_html'})
        _result = pdfkit_generator_class.send(:options_for_pdf_kit, {:title => 'the title'}, {:header_html => 'header_html_path'})

        _result[:header_html].should_not == 'bad_header_html'
        _result[:title].should == 'the title'
      end
    end
    describe "#document_path" do
      before :each do
        @document_path = File.join('documents','generated_pdf_document.pdf')
      end
      it "should raise error due to bad argument type" do
        _raise_error_message = 'first argument should be the document full storage path of type Pathname or the document name'
        lambda { pdfkit_generator_class.send(:document_path, 1) }.should raise_error(ArgumentError, _raise_error_message)
      end
      context "when only document name is sent" do
        it "should return the full document path for the pdf document to be generated" do
          pdfkit_generator_class.send(:document_path, 'generated_pdf_document.pdf').should == @document_path.to_s
        end
      end
      context "when only document full path is sent" do
        it "should return the full document path for the pdf document to be generated" do
          pdfkit_generator_class.send(:document_path, @document_path).should == @document_path.to_s
        end
      end
    end
    describe "#print" do
      def set_pre_conditions
        create_temporary_folder
        create_document_cover_html_file
        create_document_header_html_file
        create_document_body_html_file
        create_document_footer_html_file
        create_document_css_file
      end
      def unset_pre_conditions
        destroy_temporary_folder
      end
      before :all do
        @options            = {:margin_top => '0.75in', :margin_right => '0.75in', :margin_bottom => '0.75in', :margin_left => '0.75in',
                               :outline => true, :'header-spacing' => 5, :'footer-spacing' => 5 }
        @stylesheets_paths  = [path_to_css]
      end
      it "should return a contract out of html files" do
        # create necessary html files to pass to method
        set_pre_conditions

        _body_content = File.read(path_to_document_body_html_file)
        @options.merge!({ :title => 'the title', :cover => path_to_document_cover_html_file, :header_html => path_to_document_header_html_file,
                          :body  => _body_content, :footer_html => path_to_document_footer_html_file})

        _generated_pdf_document = pdfkit_generator_class.send(:print, path_to_document_pdf.to_s, @options, @stylesheets_paths)

        _generated_pdf_document.should be_instance_of File

        # destroy the created necessary html files passed to method
        unset_pre_conditions
      end
    end
  end
end