require 'spec_helper'

def app; Rack::Lint.new(@app); end

def mock_app(options = {}, conditions = {}, custom_headers = {})
  main_app = lambda { |env|
    @env = env
    full_headers = headers.merge custom_headers
    [200, full_headers, @body || ['Hello world!']]
  }

  builder = Rack::Builder.new
  builder.use PDFKit::Middleware, options, conditions
  builder.run main_app
  @app = builder.to_app
end

describe PDFKit::Middleware do
  let(:headers) { {'Content-Type' => "text/html"} }

  describe "#call" do
    describe "caching" do
      let(:headers) { {'Content-Type' => "text/html", 'ETag' => 'foo', 'Cache-Control' => 'max-age=2592000, public'} }

      context "by default" do
        before { mock_app }

        it "deletes ETag" do
          get 'http://www.example.org/public/test.pdf'
          last_response.headers["ETag"].should be_nil
        end
        it "deletes Cache-Control" do
          get 'http://www.example.org/public/test.pdf'
          last_response.headers["Cache-Control"].should be_nil
        end
      end

      context "when on" do
        before { mock_app({}, :caching => true) }

        it "preserves ETag" do
          get 'http://www.example.org/public/test.pdf'
          last_response.headers["ETag"].should_not be_nil
        end
        it "preserves Cache-Control" do
          get 'http://www.example.org/public/test.pdf'
          last_response.headers["Cache-Control"].should_not be_nil
        end
      end
    end

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

      describe ":except" do

        describe "regex" do
          describe "one" do
            before { mock_app({}, :except => %r[^/secret]) }

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
            before { mock_app({}, :except => [%r[^/prawn], %r[^/secret]]) }

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
            before { mock_app({}, :except => '/secret') }

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
            before { mock_app({}, :except => ['/prawn', '/secret']) }

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

      describe "saving generated pdf to disk" do
	before do
          #make sure tests don't find an old test_save.pdf
          File.delete('spec/test_save.pdf') if File.exists?('spec/test_save.pdf')
          File.exists?('spec/test_save.pdf').should be_false
	end

        context "when header PDFKit-save-pdf is present" do
          it "should saved the .pdf to disk" do
	    headers = { 'PDFKit-save-pdf' => 'spec/test_save.pdf' }
            mock_app({}, {only: '/public'}, headers)
	    get 'http://www.example.org/public/test_save.pdf'
            File.exists?('spec/test_save.pdf').should be_true
	  end

          it "should not raise when target directory does not exist" do
	    headers = { 'PDFKit-save-pdf' => '/this/dir/does/not/exist/spec/test_save.pdf' }
            mock_app({}, {only: '/public'}, headers)
            expect {
              get 'http://www.example.com/public/test_save.pdf'
            }.not_to raise_error(Exception)
          end
        end

        context "when header PDFKit-save-pdf is not present" do
          it "should not saved the .pdf to disk" do
            mock_app({}, {only: '/public'}, {} )
	    get 'http://www.example.org/public/test_save.pdf'
            File.exists?('spec/test_save.pdf').should be_false
          end
        end
      end
    end

  describe "remove .pdf from PATH_INFO and REQUEST_URI" do
    before { mock_app }

      context "matching" do

        specify do
          get 'http://www.example.org/public/file.pdf'
          @env["PATH_INFO"].should == "/public/file"
          @env["REQUEST_URI"].should == "/public/file"
          @env["SCRIPT_NAME"].should be_empty
        end
        specify do
          get 'http://www.example.org/public/file.txt'
          @env["PATH_INFO"].should == "/public/file.txt"
          @env["REQUEST_URI"].should be_nil
          @env["SCRIPT_NAME"].should be_empty
        end
      end

      context "subdomain matching" do
        before do
          main_app = lambda { |env|
            @env = env
            @env['SCRIPT_NAME'] = '/example.org'
            headers = {'Content-Type' => "text/html"}
            [200, headers, @body || ['Hello world!']]
          }

          builder = Rack::Builder.new
          builder.use PDFKit::Middleware
          builder.run main_app
          @app = builder.to_app
        end
        specify do
          get 'http://example.org/sub/public/file.pdf'
          @env["PATH_INFO"].should == "/sub/public/file"
          @env["REQUEST_URI"].should == "/sub/public/file"
          @env["SCRIPT_NAME"].should == "/example.org"
        end
        specify do
          get 'http://example.org/sub/public/file.txt'
          @env["PATH_INFO"].should == "/sub/public/file.txt"
          @env["REQUEST_URI"].should be_nil
          @env["SCRIPT_NAME"].should == "/example.org"
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

    it "should correctly parse relative url with double quotes" do
      @body = %{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>}
      body = @pdf.send :translate_paths, @body, @env
      body.should == "<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>"
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
