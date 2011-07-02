#encoding: UTF-8
require 'spec_helper'

describe PDFKit do

  context "initialization" do
    it "should accept HTML as the source" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      pdfkit.source.should be_html
      pdfkit.source.to_s.should == '<h1>Oh Hai</h1>'
    end

    it "should accept a URL as the source" do
      pdfkit = PDFKit.new('http://google.com')
      pdfkit.source.should be_url
      pdfkit.source.to_s.should == 'http://google.com'
    end

    it "should accept a File as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdfkit.source.should be_file
      pdfkit.source.to_s.should == file_path
    end

    it "should parse the options into a cmd line friedly format" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdfkit.options.should have_key('--page-size')
    end

    it "should provide default options" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      ['--margin-top', '--margin-right', '--margin-bottom', '--margin-left'].each do |option|
        pdfkit.options.should have_key(option)
      end
    end

    it "should default to 'UTF-8' encoding" do
      pdfkit = PDFKit.new('Captación')
      pdfkit.options['--encoding'].should == 'UTF-8'
    end

    it "should not have any stylesheedt by default" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      pdfkit.stylesheets.should be_empty
    end
  end

  context "command" do
    it "should contstruct the correct command" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter', :toc_l1_font_size => 12)
      pdfkit.command[0].should include('wkhtmltopdf')
      pdfkit.command[pdfkit.command.index('"--page-size"') + 1].should == '"Letter"'
      pdfkit.command[pdfkit.command.index('"--toc-l1-font-size"') + 1].should == '"12"'
    end

    it "will not include default options it is told to omit" do
      PDFKit.configure do |config|
        config.default_options[:disable_smart_shrinking] = true
      end

      pdfkit = PDFKit.new('html')
      pdfkit.command.should include('"--disable-smart-shrinking"')
      pdfkit = PDFKit.new('html', :disable_smart_shrinking => false)
      pdfkit.command.should_not include('"--disable-smart-shrinking"')
    end

    it "should encapsulate string arguments in quotes" do
      pdfkit = PDFKit.new('html', :header_center => "foo [page]")
      pdfkit.command[pdfkit.command.index('"--header-center"') + 1].should == '"foo [page]"'
    end

    it "read the source from stdin if it is html" do
      pdfkit = PDFKit.new('html')
      pdfkit.command[-2..-1].should == ['"-"', '"-"']
    end

    it "specify the URL to the source if it is a url" do
      pdfkit = PDFKit.new('http://google.com')
      pdfkit.command[-2..-1].should == ['"http://google.com"', '"-"']
    end

    it "should specify the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdfkit.command[-2..-1].should == [%Q{"#{file_path}"}, '"-"']
    end

    it "should specify the path for the ouput if a apth is given" do
      file_path = "/path/to/output.pdf"
      pdfkit = PDFKit.new("html")
      pdfkit.command(file_path).last.should == %Q{"#{file_path}"}
    end

    it "should detect special pdfkit meta tags" do
      body = %{
        <html>
          <head>
            <meta name="pdfkit-page_size" content="Legal"/>
            <meta name="pdfkit-orientation" content="Landscape"/>
          </head>
        </html>
      }
      pdfkit = PDFKit.new(body)
      pdfkit.command[pdfkit.command.index('"--page-size"') + 1].should == '"Legal"'
      pdfkit.command[pdfkit.command.index('"--orientation"') + 1].should == '"Landscape"'
    end

    it "should detect special pdfkit meta tags despite bad markup" do
      body = %{
        <html>
          <head>
            <meta name="pdfkit-page_size" content="Legal"/>
            <meta name="pdfkit-orientation" content="Landscape"/>
          </head>
          <br>
        </html>
      }
      pdfkit = PDFKit.new(body)
      pdfkit.command[pdfkit.command.index('"--page-size"') + 1].should == '"Legal"'
      pdfkit.command[pdfkit.command.index('"--orientation"') + 1].should == '"Landscape"'
    end

    it "should skip non-pdfkit meta tags" do
      body = %{
        <html>
          <head>
            <meta name="test-page_size" content="Legal"/>
            <meta name="pdfkit-orientation" content="Landscape"/>
          </head>
          <br>
        </html>
      }
      pdfkit = PDFKit.new(body)
      pdfkit.command[pdfkit.command.index('"--orientation"') + 1].should == '"Landscape"'
    end

  end

  context "#to_pdf" do
    it "should generate a PDF of the HTML" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end

    it "should generate a PDF with a numerical parameter" do
      pdfkit = PDFKit.new('html', :header_spacing => 1)
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end

    it "should generate a PDF with a symbol parameter" do
      pdfkit = PDFKit.new('html', :page_size => :Letter)
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end

    it "should have the stylesheet added to the head if it has one" do
      pdfkit = PDFKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style>")
    end

    it "should prepend style tags if the HTML doesn't have a head tag" do
      pdfkit = PDFKit.new("<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style><html>")
    end

    it "should throw an error if the source is not html and stylesheets have been added" do
      pdfkit = PDFKit.new('http://google.com')
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      lambda { pdfkit.to_pdf }.should raise_error(PDFKit::ImproperSourceError)
    end

    it "should be able to deal with ActiveSupport::SafeBuffer" do
      pdfkit = PDFKit.new(ActiveSupport::SafeBuffer.new "<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style></head>")
    end

  end

  context "#to_file" do
    before do
      @file_path = File.join(SPEC_ROOT,'fixtures','test.pdf')
      File.delete(@file_path) if File.exist?(@file_path)
    end

    after do
      File.delete(@file_path)
    end

    it "should create a file with the PDF as content" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      file = pdfkit.to_file(@file_path)
      file.should be_instance_of(File)
      File.read(file.path)[0...4].should == "%PDF" # PDF Signature at beginning of file
    end

    it "should not truncate data (in Ruby 1.8.6)" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdf_data = pdfkit.to_pdf
      file = pdfkit.to_file(@file_path)
      file_data = open(@file_path, 'rb') {|io| io.read }
      pdf_data.size.should == file_data.size
    end
  end

  context "security" do
    before do
      @test_path = File.join(SPEC_ROOT,'fixtures','security-oops')
      File.delete(@test_path) if File.exist?(@test_path)
    end

    after do
      File.delete(@test_path) if File.exist?(@test_path)
    end

    it "should not allow shell injection in options" do
      pdfkit = PDFKit.new('html', :header_center => "a title\"; touch #{@test_path} #")
      pdfkit.to_pdf
      File.exist?(@test_path).should be_false
    end
  end

end
