# frozen_string_literal: true

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
    {'content-type' => "text/html"}
  end

  describe "#call" do

    describe 'threadsafety' do
      before { mock_app }
      it 'is threadsafe' do
        n = 30
        extensions = Array.new(n) { rand > 0.5 ? 'html' : 'pdf' }
        actual_content_types = Hash.new

        threads = (0...n).map { |i|
          Thread.new do
            resp = get("http://www.example.org/public/test.#{extensions[i]}")
            actual_content_types[i] = resp.content_type
          end
        }

        threads.each(&:join)

        extensions.each_with_index do |extension, index|
          result = actual_content_types[index]
          case extension
          when 'html', 'txt', 'csv'
            expect(result).to eq("text/#{extension}")
          when 'pdf'
            expect(result).to eq('application/pdf')
          end
        end
      end
    end

    describe "caching" do
      let(:headers) do
        {
          'content-type' => "text/html",
          'etag' => 'foo',
          'cache-control' => 'max-age=2592000, public'
        }
      end

      context "by default" do
        before { mock_app }

        it "deletes etag" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["etag"]).to be_nil
        end
        it "deletes cache-control" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["cache-control"]).to be_nil
        end
      end

      context "when on" do
        before { mock_app({}, :caching => true) }

        it "preserves etag" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["etag"]).not_to be_nil
        end

        it "preserves cache-control" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["cache-control"]).not_to be_nil
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
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one regex

          describe "multiple" do
            before { mock_app({}, :only => [%r[^/invoice], %r[^/public]]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
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
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one string

          describe "multiple" do
            before { mock_app({}, :only => ['/invoice', '/public']) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
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
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one regex

          describe "multiple" do
            before { mock_app({}, :except => [%r[^/prawn], %r[^/secret]]) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
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
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # one string

          describe "multiple" do
            before { mock_app({}, :except => ['/prawn', '/secret']) }

            context "matching" do
              specify do
                get 'http://www.example.org/public/test.pdf'
                expect(last_response.headers["content-type"]).to eq("application/pdf")
                expect(last_response.body.bytesize).to eq(PDFKit.new("Hello world!").to_pdf.bytesize)
              end
            end

            context "not matching" do
              specify do
                get 'http://www.example.org/secret/test.pdf'
                expect(last_response.headers["content-type"]).to eq("text/html")
                expect(last_response.body).to eq("Hello world!")
              end
            end
          end # multiple string
        end # string

      end

      describe "saving generated pdf to disk" do
        before do
          #make sure tests don't find an old test_save.pdf
          File.delete('spec/test_save.pdf') if File.exist?('spec/test_save.pdf')
          expect(File.exist?('spec/test_save.pdf')).to eq(false)
        end

        context "when header PDFKit-save-pdf is present" do
          it "saves the .pdf to disk" do
            headers = { 'PDFKit-save-pdf' => 'spec/test_save.pdf' }
            mock_app({}, {only: '/public'}, headers)
            get 'http://www.example.org/public/test_save.pdf'
            expect(File.exist?('spec/test_save.pdf')).to eq(true)
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
            expect(File.exist?('spec/test_save.pdf')).to eq(false)
          end
        end
      end

      describe 'javascript delay' do
        context 'when header PDFKit-javascript-delay is present' do
          it 'passes header value through to PDFKit initialiser' do
            expect(PDFKit).to receive(:new).with('Hello world!', {
              root_url: 'http://www.example.com/', protocol: 'http', javascript_delay: 4321
            }).and_call_original

            headers = { 'PDFKit-javascript-delay' => '4321' }
            mock_app({}, { only: '/public' }, headers)
            get 'http://www.example.com/public/test_save.pdf'
          end

          it 'handles invalid content in header' do
            expect(PDFKit).to receive(:new).with('Hello world!', {
              root_url: 'http://www.example.com/', protocol: 'http', javascript_delay: 0
            }).and_call_original

            headers = { 'PDFKit-javascript-delay' => 'invalid' }
            mock_app({}, { only: '/public' }, headers)
            get 'http://www.example.com/public/test_save.pdf'
          end

          it 'overrides default option' do
            expect(PDFKit).to receive(:new).with('Hello world!', {
              root_url: 'http://www.example.com/', protocol: 'http', javascript_delay: 4321
            }).and_call_original

            headers = { 'PDFKit-javascript-delay' => '4321' }
            mock_app({ javascript_delay: 1234 }, { only: '/public' }, headers)
            get 'http://www.example.com/public/test_save.pdf'
          end
        end

        context 'when header PDFKit-javascript-delay is not present' do
          it 'passes through default option' do
            expect(PDFKit).to receive(:new).with('Hello world!', {
              root_url: 'http://www.example.com/', protocol: 'http', javascript_delay: 1234
            }).and_call_original

            mock_app({ javascript_delay: 1234 }, { only: '/public' }, { })
            get 'http://www.example.com/public/test_save.pdf'
          end
        end
      end

      describe ":disposition" do
        describe "doesn't overwrite existing value" do
          let(:headers) do
            super().merge({
              'content-disposition' => 'attachment; filename=report-20200101.pdf'
            })
          end

          specify do
            mock_app({}, { :disposition => 'inline' })
            get 'http://www.example.org/public/test.pdf'
            expect(last_response.headers["content-disposition"]).to eq('attachment; filename=report-20200101.pdf')
          end
        end

        describe "inline or blank" do
          context "default" do
            specify do
              mock_app
              get 'http://www.example.org/public/test.pdf'
              expect(last_response.headers["content-disposition"]).to eq("inline")
            end
          end

          context "inline" do
            specify do
              mock_app({}, { :disposition => 'inline'  })
              get 'http://www.example.org/public/test.pdf'
              expect(last_response.headers["content-disposition"]).to eq("inline")
            end
          end
        end

        describe "attachment" do
          context "attachment" do
            specify do
              mock_app({}, { :disposition => 'attachment'  })
              get 'http://www.example.org/public/test.pdf'
              expect(last_response.headers["content-disposition"]).to eq("attachment")
            end
          end

          context "attachment with filename" do
            specify do
              mock_app({}, { :disposition => 'attachment; filename=report.pdf'  })
              get 'http://www.example.org/public/test.pdf'
              expect(last_response.headers["content-disposition"]).to eq("attachment; filename=report.pdf")
            end
          end
        end
      end

      describe "error handling" do
        let(:error) { StandardError.new("Something went wrong") }

        context "errors raised by PDF generation" do
          specify do
            mock_app
            allow(PDFKit).to receive(:new).and_raise(error)
            get 'http://www.example.org/public/test.pdf'
            expect(last_response.status).to eq(500)
            expect(last_response.body).to eq(error.message)
          end
        end

        context "errors raised upstream" do
          specify do
            mock_app
            allow(@app).to receive(:call).and_raise(error)

            expect {
              get 'http://www.example.org/public/test.pdf'
            }.to raise_error(error)
          end
        end
      end
    end

    describe "content type header" do
      before { mock_app }

      context "lower case" do
        specify "header gets correctly updated" do
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["content-type"]).to eq("application/pdf")
        end
      end

      context "mixed case" do
        let(:headers) do
          {'Content-Type' => "text/html"}
        end

        specify "header gets correctly updated" do
          pending("this test only applies to rack 2.x and is rejected by rack 3.x") if Rack.release >= "3.0.0"
          get 'http://www.example.org/public/test.pdf'
          expect(last_response.headers["Content-Type"]).to eq("application/pdf")
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
            headers = {'content-type' => "text/html"}
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
end
