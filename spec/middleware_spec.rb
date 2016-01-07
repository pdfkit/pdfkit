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

  describe "#root_url and #protocol" do
    before do
      @pdf = PDFKit::Middleware.new({})
      @env = { 'REQUEST_URI' => 'http://example.com/document.pdf', 'rack.url_scheme' => 'http', 'HTTP_HOST' => 'example.com' }
    end

    context 'when root_url is not configured' do
      it "infers the root_url and protocol from the environment" do
        root_url = @pdf.send(:root_url, @env)
        protocol = @pdf.send(:protocol, @env)

        expect(root_url).to eq('http://example.com/')
        expect(protocol).to eq('http')
      end
    end

    context 'when root_url is configured' do
      before do
        PDFKit.configuration.root_url = 'http://example.net/'
      end
      after do
        PDFKit.configuration.root_url = nil
      end

      it "takes the root_url from the configuration, and infers the protocol from the environment" do
        root_url = @pdf.send(:root_url, @env)
        protocol = @pdf.send(:protocol, @env)

        expect(root_url).to eq('http://example.net/')
        expect(protocol).to eq('http')
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
