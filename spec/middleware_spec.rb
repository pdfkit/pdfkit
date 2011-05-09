require 'spec_helper'

def app; Rack::Lint.new(@app); end

def mock_app(options = {}, conditions = {})
  main_app = lambda { |env|
    @env = env
    headers = {'Content-Type' => "text/html"}
    [200, headers, @body || ['Hello world!']]
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
            before { mock_app({}, :only => %r[^/public]) }

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
            before { mock_app({}, :only => [%r[^/invoice], %r[^/public]]) }

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
            before { mock_app({}, :only => ['/invoice', '/public']) }

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

    describe "remove .pdf from PATH_INFO and REQUEST_URI" do
      before { mock_app }

      context "matching" do
        specify do
          get 'http://www.example.org/public/file.pdf'
          @env["PATH_INFO"].should == "/public/file"
          @env["REQUEST_URI"].should == "/public/file"
        end
        specify do
          get 'http://www.example.org/public/file.txt'
          @env["PATH_INFO"].should == "/public/file.txt"
          @env["REQUEST_URI"].should be_nil
        end
      end

    end
  end

  describe "#translate_paths" do
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
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
  
  describe "#translate_paths with root_url configuration" do
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
      PDFKit.configure do |config|
        config.root_url = "http://example.net/"
      end
    end

    it "should add the root_url" do
      @body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/test.png" /></body></html>}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<html><head><link href='http://example.net/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.net/test.png\" /></body></html>"
    end
    
    after do
      PDFKit.configure do |config|
        config.root_url = nil
      end
    end
  end

  it "should not get stuck rendering each request as pdf" do
    mock_app
    # false by default. No requests.
    @app.send(:rendering_pdf?).should be_false

    # Remain false on a normal request
    get 'http://www.example.org/public/file'
    @app.send(:rendering_pdf?).should be_false

    # Return true on a pdf request.
    get 'http://www.example.org/public/file.pdf'
    @app.send(:rendering_pdf?).should be_true

    # Restore to false on any non-pdf request.
    get 'http://www.example.org/public/file'
    @app.send(:rendering_pdf?).should be_false
  end

end
