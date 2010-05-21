require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PDFKit do
  
  context "initialization" do
    it "should take HTML for the renderer" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      pdfkit.html.should == '<h1>Oh Hai</h1>'
    end
    
    it "should parse the options into a cmd line friedly format" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdfkit.options.should have_key('--page-size')
    end
    
    it "should provide default options" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      ['--disable-smart-shrinking', '--margin-top', '--margin-right', '--margin-bottom', '--margin-left'].each do |option|
        pdfkit.options.should have_key(option)
      end
    end
    
    it "should not have any stylesheedt by default" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      pdfkit.stylesheets.should be_empty
    end
  end
  
  context "command" do
    it "should contstruct the correct command" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdfkit.command.should include('wkhtmltopdf')
      pdfkit.command.should include('--page-size Letter')
    end
  end
  
  context "to_pdf" do
    it "should generate a PDF of the HTML" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdf = pdfkit.to_pdf
      pdf.should match(/^%PDF/) # PDF Signature at beginning of file
    end
    
    it "should have the stylesheet added to the head if it has one" do
      pdfkit = PDFKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.expand_path(File.dirname(__FILE__) + '/fixtures/example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.html.should include("<style>#{File.read(css)}</style>")
    end
    
    it "should prepend style tags if the HTML doesn't have a head tag" do
      pdfkit = PDFKit.new("<html><body>Hai!</body></html>")
      css = File.expand_path(File.dirname(__FILE__) + '/fixtures/example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.html.should include("<style>#{File.read(css)}</style><html>")
    end
  end
  
end
