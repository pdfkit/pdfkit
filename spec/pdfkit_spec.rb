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

    it "should parse complex options into a cmd line friedly format" do
      pdfkit = PDFKit.new('html', :replace => {'value' => 'something else'} )
      pdfkit.options.should have_key('--replace')
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
      pdfkit = PDFKit.new('html', :page_size => 'Letter', :toc_l1_font_size => 12, :replace => {'foo' => 'bar'})
      command = pdfkit.command
      command.should include "wkhtmltopdf"
      command.should include "--page-size Letter"
      command.should include "--toc-l1-font-size 12"
      command.should include "--replace foo bar"
    end

    it "should setup one cookie only" do
      pdfkit = PDFKit.new('html', cookie: {cookie_name: :cookie_value})
      command = pdfkit.command
      command.should include "--cookie cookie_name cookie_value"
    end

    it "should setup multiple cookies when passed a hash" do
      pdfkit = PDFKit.new('html', :cookie => {:cookie_name1 => :cookie_val1, :cookie_name2 => :cookie_val2})
      command = pdfkit.command
      command.should include "--cookie cookie_name1 cookie_val1"
      command.should include "--cookie cookie_name2 cookie_val2"
    end

    it "should setup multiple cookies when passed an array of tuples" do
      pdfkit = PDFKit.new('html', :cookie => [[:cookie_name1, :cookie_val1], [:cookie_name2, :cookie_val2]])
      command = pdfkit.command
      command.should include "--cookie cookie_name1 cookie_val1"
      command.should include "--cookie cookie_name2 cookie_val2"
    end

    it "will not include default options it is told to omit" do
      PDFKit.configure do |config|
        config.default_options[:disable_smart_shrinking] = true
      end

      pdfkit = PDFKit.new('html')
      pdfkit.command.should include('--disable-smart-shrinking')
      pdfkit = PDFKit.new('html', :disable_smart_shrinking => false)
      pdfkit.command.should_not include('--disable-smart-shrinking')
    end

    it "should encapsulate string arguments in quotes" do
      pdfkit = PDFKit.new('html', :header_center => "foo [page]")
      pdfkit.command.should include "--header-center foo\\ \\[page\\]"
    end

    it "should sanitize string arguments" do
      pdfkit = PDFKit.new('html', :header_center => "$(ls)")
      pdfkit.command.should include "--header-center \\$\\(ls\\)"
    end

    it "read the source from stdin if it is html" do
      pdfkit = PDFKit.new('html')
      pdfkit.command.should match /- -$/
    end

    it "specify the URL to the source if it is a url" do
      pdfkit = PDFKit.new('http://google.com')
      pdfkit.command.should match /http:\/\/google.com -$/
    end

    it "should specify the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdfkit.command.should match /#{file_path} -$/
    end

    it "should specify the path for the ouput if a apth is given" do
      file_path = "/path/to/output.pdf"
      pdfkit = PDFKit.new("html")
      pdfkit.command(file_path).should match /#{file_path}$/
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
      command = pdfkit.command
      command.should include "--page-size Legal"
      command.should include "--orientation Landscape"
    end

    it "should detect cookies meta tag" do
      body = %{
        <html>
          <head>
            <meta name="pdfkit-cookie rails_session" content='rails_session_value' />
            <meta name="pdfkit-cookie cookie_variable" content='cookie_variable_value' />
          </head>
        </html>
      }
      pdfkit = PDFKit.new(body)
      command = pdfkit.command
      command.should include "--cookie rails_session rails_session_value --cookie cookie_variable cookie_variable_value"
    end

    it "should detect disable_smart_shrinking meta tag" do
      body = %{
        <html>
          <head>
            <meta name="pdfkit-disable_smart_shrinking" content="true"/>
          </head>
        </html>
      }
      pdfkit = PDFKit.new(body)
      command = pdfkit.command
      command.should include "--disable-smart-shrinking"
      command.should_not include "--disable-smart-shrinking true"
    end

    it "should detect names with hyphens instead of underscores" do
      body = %{
        <html>
          <head>
            <meta content='Portrait' name='pdfkit-orientation'/>
            <meta content="10mm" name="pdfkit-margin-bottom"/>
          </head>
          <br>
        </html>
      }
      pdfkit = PDFKit.new(body)
      pdfkit.command.should_not include 'name\='
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
      command = pdfkit.command
      command.should include "--page-size Legal"
      command.should include "--orientation Landscape"
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
      command = pdfkit.command
      command.should_not include "--page-size Legal"
      command.should include "--orientation Landscape"
    end

    it "should not use quiet" do
      pdfkit = PDFKit.new('html', quiet: false)
      pdfkit.command.should_not include '--quiet'
    end

    it "should use quiet option by defautl" do
      pdfkit = PDFKit.new('html')
      pdfkit.command.should include '--quiet'
    end

    it "should not use quiet option in verbose mode" do
      PDFKit.configure do |config|
        config.verbose = true
      end

      pdfkit = PDFKit.new('html')
      pdfkit.command.should_not include '--quiet'

      PDFKit.configure do |config|
        config.verbose = false
      end
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

    it "should escape \\X in stylesheets" do
      pdfkit = PDFKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example_with_hex_symbol.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style></head>")
    end

    #NOTICE: This test is failed if use wkhtmltopdf-binary (0.9.9.1)
    it "should throw an error if it is unable to connect" do
      pdfkit = PDFKit.new("http://google.com/this-should-not-be-found/404.html")
      lambda { pdfkit.to_pdf }.should raise_error /exitstatus=2/
    end

    it "should not throw an error if it is unable to connect", pending: 'this test works for wkhtmltopdf-binary (0.9.9.1)' do
      pdfkit = PDFKit.new("http://localhost/this-should-not-be-found/404.html")
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at the beginning
    end

    it "should generate PDF if there are missing assets" do
      pdfkit = PDFKit.new("<html><body><img alt='' src='http://example.com/surely-it-doesnt-exist.gif' /></body></html>", ignore_load_errors: true)
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at the beginning
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
