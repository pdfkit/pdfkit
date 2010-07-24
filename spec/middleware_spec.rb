require 'spec_helper'

describe PDFKit::Middleware do
  describe "#translate_paths" do
    
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = {'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com'}
    end

    it "should correctly parse relative url with single quotes" do
      @body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src='/test.png' /></body></html>}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<html><head><link href=\"http://example.com/stylesheets/application.css\" media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.com/test.png\" /></body></html>"
    end

    it "should correctly parse relative url with double quotes" do
      @body = %{<link href="/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<link href=\"http://example.com/stylesheets/application.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
    end

    it "should return the body even if there are no valid substitutions found" do
      @body = "NO MATCH"
      body = @pdf.send :translate_paths, @body, @env
      body.should == "NO MATCH"
    end
  end
  
  describe "#set_request_to_render_as_pdf" do
    
    before do      
      @pdf = PDFKit::Middleware.new({})

      @pdf_env = {'PATH_INFO' => Pathname.new("file.pdf"), 'REQUEST_URI' => Pathname.new("file.pdf")}
      @non_pdf_env = {'PATH_INFO' => Pathname.new("file.txt"), 'REQUEST_URI' => Pathname.new("file.txt")}
    end
    
    it "should replace .pdf in PATH_INFO when the extname is .pdf" do
      @pdf.send :set_request_to_render_as_pdf, @pdf_env
      @pdf_env['PATH_INFO'].should == "file"
    end
    
    it "should replace .pdf in REQUEST_URI when the extname is .pdf" do
      @pdf.send :set_request_to_render_as_pdf, @pdf_env
      @pdf_env['REQUEST_URI'].should == "file"
    end    
  end
end
