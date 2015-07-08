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
  let(:headers) do
    {'Content-Type' => "text/html"}
  end

  describe "#call" do
    describe "caching" do
      let(:headers) do
        {
          'Content-Type' => "text/html",
          'ETag' => 'foo',
          'Cache-Control' => 'max-age=2592000, public'
        }
      end

      context "by default" do
        before { mock_app }

        it "deletes ETag" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["ETag"]).to be_nil
        end
        it "deletes Cache-Control" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["Cache-Control"]).to be_nil
        end
      end

      context "when on" do
        before { mock_app({}, :caching => true) }

        it "preserves ETag" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["ETag"]).not_to be_nil
        end

        it "preserves Cache-Control" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["Cache-Control"]).not_to be_nil
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
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one regex

          describe "multiple" do
            before { mock_app({}, :only => [%r[^/invoice], %r[^/public]]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
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
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one string

          describe "multiple" do
            before { mock_app({}, :only => ['/invoice', '/public']) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
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
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one regex

          describe "multiple" do
            before { mock_app({}, :except => [%r[^/prawn], %r[^/secret]]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
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
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one string

          describe "multiple" do
            before { mock_app({}, :except => ['/prawn', '/secret']) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["Content-Type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # multiple string
        end # string

      end

      describe "saving generated pdf to disk" do
	before do
          #make sure tests don't find an old test_save.pdf
          File.delete('spec/test_save.pdf') if File.exists?('spec/test_save.pdf')
          expect(File.exists?('spec/test_save.pdf')).to eq(false)
	end

        context "when header PDFKit-save-pdf is present" do
          it "saves the .pdf to disk" do
	    headers = { 'PDFKit-save-pdf' => 'spec/test_save.pdf' }
            mock_app({}, {only: '/public'}, headers)
	    get 'http://www.example.org/public/test_save.pdf'
            expect(File.exists?('spec/test_save.pdf')).to eq(true)
	  end

          it "does not raise when target directory does not exist" do
	    headers = { 'PDFKit-save-pdf' => '/this/dir/does/not/exist/spec/test_save.pdf' }
            mock_app({}, {only: '/public'}, headers)
            expect {
              get 'http://www.example.com/public/test_save.pdf'
            }.not_to raise_error
          end
        end

        context "when header PDFKit-save-pdf is not present" do
          it "does not saved the .pdf to disk" do
            mock_app({}, {only: '/public'}, {} )
	    get 'http://www.example.org/public/test_save.pdf'
            expect(File.exists?('spec/test_save.pdf')).to eq(false)
          end
        end
      end
    end

  describe "remove .pdf from PATH_INFO and REQUEST_URI" do
    before { mock_app }

      context "matching" do

        specify do
          get 'http://www.example.org/public/file.pdf'
          expect(@env["PATH_INFO"]).to eq("/public/file")
          expect(@env["REQUEST_URI"]).to eq("/public/file")
          expect(@env["SCRIPT_NAME"]).to be_empty
        end
        specify do
          get 'http://www.example.org/public/file.txt'
          expect(@env["PATH_INFO"]).to eq("/public/file.txt")
          expect(@env["REQUEST_URI"]).to be_nil
          expect(@env["SCRIPT_NAME"]).to be_empty
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
          expect(@env["PATH_INFO"]).to eq("/sub/public/file")
          expect(@env["REQUEST_URI"]).to eq("/sub/public/file")
          expect(@env["SCRIPT_NAME"]).to eq("/example.org")
        end
        specify do
          get 'http://example.org/sub/public/file.txt'
          expect(@env["PATH_INFO"]).to eq("/sub/public/file.txt")
          expect(@env["REQUEST_URI"]).to be_nil
          expect(@env["SCRIPT_NAME"]).to eq("/example.org")
        end
      end

    end
  end

  describe "#translate_paths" do
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
    end

    it "correctly parses relative url with single quotes" do
      @body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/test.png" /></body></html>}
      body = @pdf.send :translate_paths, @body, @env
      expect(body).to eq("<html><head><link href='http://example.com/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.com/test.png\" /></body></html>")
    end

    it "correctly parses relative url with double quotes" do
      @body = %{<link href="/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />}
      body = @pdf.send :translate_paths, @body, @env
      expect(body).to eq("<link href=\"http://example.com/stylesheets/application.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />")
    end

    it "correctly parses relative url with double quotes" do
      @body = %{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>}
      body = @pdf.send :translate_paths, @body, @env
      expect(body).to eq("<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>")
    end

    it "correctly parses multiple tags where first one is root url" do
      @body = %{<a href='/'><img src='/logo.jpg' ></a>}
      body = @pdf.send :translate_paths, @body, @env
      expect(body).to eq "<a href='http://example.com/'><img src='http://example.com/logo.jpg' ></a>"
    end

    it "returns the body even if there are no valid substitutions found" do
      @body = "NO MATCH"
      body = @pdf.send :translate_paths, @body, @env
      expect(body).to eq("NO MATCH")
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

    it "adds the root_url" do
      @body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/test.png" /></body></html>}
      body = @pdf.send :translate_paths, @body, @env
      expect(body).to eq("<html><head><link href='http://example.net/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.net/test.png\" /></body></html>")
    end

    after do
      PDFKit.configure do |config|
        config.root_url = nil
      end
    end
  end

  it "does not get stuck rendering each request as pdf" do
    mock_app
    # false by default. No requests.
    expect(@app.send(:rendering_pdf?)).to eq(false)

    # Remain false on a normal request
    get 'http://www.example.org/public/file'
    expect(@app.send(:rendering_pdf?)).to eq(false)

    # Return true on a pdf request.
    get 'http://www.example.org/public/file.pdf'
    expect(@app.send(:rendering_pdf?)).to eq(true)

    # Restore to false on any non-pdf request.
    get 'http://www.example.org/public/file'
    expect(@app.send(:rendering_pdf?)).to eq(false)
  end
end
