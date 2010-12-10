require 'spec_helper'

def app; Rack::Lint.new(@app); end

def mock_app(options = {}, conditions = {})
  main_app = lambda { |env|
    request = Rack::Request.new(env)
    headers = {'Content-Type' => "text/html"}
    headers['Set-Cookie'] = "id=1; path=/\ntoken=abc; path=/; secure; HttpOnly"
    [200, headers, ['Hello world!']]
  }
  
  builder = Rack::Builder.new
  builder.use PDFKit::Middleware, options, conditions
  builder.run main_app
  @app = builder.to_app
end

describe PDFKit::Middleware do
  
  describe "#call" do
    describe "conditions" do
      describe ":only" do
        
        describe "regex" do
          describe "one" do
            before { mock_app({}, :only => /^\/public/) }
            
            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                last_response.headers["Content-Type"].should == "application/pdf"
                last_response.body.bytesize.should == PDFKit.new("Hello world!").to_pdf.bytesize
              end
            end
            
            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # one regex
          
          describe "multiple" do
            before { mock_app({}, :only => [/^\/foo/, /^\/public/]) }
            
            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                last_response.headers["Content-Type"].should == "application/pdf"
                last_response.body.bytesize.should == PDFKit.new("Hello world!").to_pdf.bytesize
              end
            end
            
            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # multiple regex
        end # regex
        
        describe "string" do
          describe "one" do
            before { mock_app({}, :only => '/public') }
            
            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                last_response.headers["Content-Type"].should == "application/pdf"
                last_response.body.bytesize.should == PDFKit.new("Hello world!").to_pdf.bytesize
              end
            end
            
            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # one string
          
          describe "multiple" do
            before { mock_app({}, :only => ['/foo', '/public']) }
            
            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                last_response.headers["Content-Type"].should == "application/pdf"
                last_response.body.bytesize.should == PDFKit.new("Hello world!").to_pdf.bytesize
              end
            end
            
            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                last_response.headers["Content-Type"].should == "text/html"
                last_response.body.should == "Hello world!"
              end
            end
          end # multiple string
        end # string
        
      end
    end
  end
  
  describe "#translate_paths" do
    
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = {'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com'}
    end

    it "should correctly parse relative url with single quotes" do
      @body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/test.png" /></body></html>}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<html><head><link href='http://example.com/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.com/test.png\" /></body></html>"
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
