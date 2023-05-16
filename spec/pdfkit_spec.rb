#encoding: UTF-8
# frozen_string_literal: true

require 'spec_helper'

describe PDFKit do
  describe "initialization" do
    # Source
    it "accepts HTML as the source" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      expect(pdfkit.source).to be_html
      expect(pdfkit.source.to_s).to eq('<h1>Oh Hai</h1>')
    end

    it "accepts a URL as the source" do
      pdfkit = PDFKit.new('http://google.com')
      expect(pdfkit.source).to be_url
      expect(pdfkit.source.to_s).to eq('http://google.com')
    end

    it "accepts a File as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      expect(pdfkit.source).to be_file
      expect(pdfkit.source.to_s).to eq(file_path)
    end

    it "accepts a Tempfile as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(Tempfile.new(file_path))
      expect(pdfkit.source).to be_file
      expect(pdfkit.source.to_s).to match(/^#{Dir.tmpdir}/)
    end

    # Options
    ## options keys
    it "drops options without values" do
      pdfkit = PDFKit.new('html', :page_size => nil)
      expect(pdfkit.options).not_to have_key('--page-size')
    end

    it "transforms keys into command-line arguments" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      expect(pdfkit.options).to have_key('--page-size')
    end

    it "transforms complex keys into command-line arguments" do
      pdfkit = PDFKit.new('html', :header_left => {'value' => 'something else'} )
      expect(pdfkit.options).to have_key('--header-left')
    end

    it "drops options with false or falsey values" do
      pdfkit = PDFKit.new('html', disable_smart_shrinking: false)
      expect(pdfkit.options).not_to have_key('--disable-smart-shrinking')
    end

    ## options values
    it "parses string option values into strings" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      expect(pdfkit.options['--page-size']).to eql 'Letter'
    end

    it "drops option values of 'true'" do
      pdfkit = PDFKit.new('html', disable_smart_shrinking: true)
      expect(pdfkit.options).to have_key('--disable-smart-shrinking')
      expect(pdfkit.options['--disable-smart-shrinking']).to be_nil
    end

    it "parses unknown value formats by transforming them into strings" do
      pdfkit = PDFKit.new('html', image_dpi: 300)
      expect(pdfkit.options['--image-dpi']).to eql '300'
    end

    it "parses hash option values into an array" do
      pdfkit = PDFKit.new('html', :header_left => {'value' => 'something else'} )
      expect(pdfkit.options['--header-left']).to eql ['value', 'something else']
    end

    it "flattens hash options into the key" do
      pdfkit = PDFKit.new('html', :cookie => {:cookie_name1 => :cookie_val1, :cookie_name2 => :cookie_val2})
      expect(pdfkit.options).not_to have_key('--cookie')
      expect(pdfkit.options[['--cookie', 'cookie_name1']]).to eql 'cookie_val1'
      expect(pdfkit.options[['--cookie', 'cookie_name2']]).to eql 'cookie_val2'
    end

    it "parses array option values into a string" do
      pdfkit = PDFKit.new('html', :header_left => ['value', 'something else'] )
      expect(pdfkit.options['--header-left']).to eql ['value', 'something else']
    end

    it "flattens array options" do
      pdfkit = PDFKit.new('html', :cookie => [[:cookie_name1, :cookie_val1], [:cookie_name2, :cookie_val2]])
      expect(pdfkit.options).not_to have_key('--cookie')
      expect(pdfkit.options[['--cookie', 'cookie_name1']]).to eql 'cookie_val1'
      expect(pdfkit.options[['--cookie', 'cookie_name2']]).to eql 'cookie_val2'
    end

    ## default options
    it "provides default options" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      ['--margin-top', '--margin-right', '--margin-bottom', '--margin-left'].each do |option|
        expect(pdfkit.options).to have_key(option)
      end
    end

    it "allows overriding default options" do
      pdfkit = PDFKit.new('html', :page_size => 'A4')
      expect(pdfkit.options['--page-size']).to eql 'A4'
    end

    it "defaults to 'UTF-8' encoding" do
      pdfkit = PDFKit.new('Captación')
      expect(pdfkit.options['--encoding']).to eq('UTF-8')
    end

    it "handles repeatable values which are strings" do
      pdfkit = PDFKit.new('html', allow: 'http://myapp.com')
      expect(pdfkit.options).to have_key ['--allow', 'http://myapp.com']
      expect(pdfkit.options[['--allow', 'http://myapp.com']]).to eql nil
    end

    it "handles repeatable values which are hashes" do
      pdfkit = PDFKit.new('html', allow: { 'http://myapp.com' => nil, 'http://google.com' => nil })
      expect(pdfkit.options).to have_key ['--allow', 'http://myapp.com']
      expect(pdfkit.options).to have_key ['--allow', 'http://google.com']
      expect(pdfkit.options[['--allow', 'http://myapp.com']]).to eql nil
      expect(pdfkit.options[['--allow', 'http://google.com']]).to eql nil
    end

    it "handles repeatable values which are arrays" do
      pdfkit = PDFKit.new('html', allow: ['http://myapp.com', 'http://google.com'])
      expect(pdfkit.options).to have_key ['--allow', 'http://myapp.com']
      expect(pdfkit.options).to have_key ['--allow', 'http://google.com']
      expect(pdfkit.options[['--allow', 'http://myapp.com']]).to eql nil
      expect(pdfkit.options[['--allow', 'http://google.com']]).to eql nil
    end

    it "does not prepend cover option with --" do
      pdfkit = PDFKit.new('html', "cover" => 'http://google.com')
      expect(pdfkit.options).to have_key('cover')
    end

    it "does not prepend the toc option with --" do
      pdfkit = PDFKit.new('html', 'toc' => '')
      expect(pdfkit.options).to have_key('toc')
    end

    it "handles cover and toc  params passed as symbols" do
      pdfkit = PDFKit.new('html', {toc: true})
      expect(pdfkit.options).to have_key('toc')
    end

    # Stylesheets
    it "has no stylesheet by default" do
      pdfkit = PDFKit.new('<h1>Oh Hai</h1>')
      expect(pdfkit.stylesheets).to be_empty
    end
  end

  describe "#options" do
    # #options is an attr_reader, but it doesn't really matter. See these two examples:
    it "cannot be externally overwritten entirely" do
      pdfkit = PDFKit.new('html', :page_size => 'A4')
      expect{ pdfkit.options = {} }.to raise_error(NoMethodError)
    end

    it "has attributes that are externally mutable" do
      pdfkit = PDFKit.new('html', :page_size => 'A4')
      pdfkit.options['--page-size'] = 'Letter'
      expect(pdfkit.options['--page-size']).to eql 'Letter'
    end
  end

  describe "#command" do
    it "constructs the correct command" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter', :toc_l1_font_size => 12, :replace => {'foo' => 'bar'})
      command = pdfkit.command
      expect(command.first).to match(/wkhtmltopdf/)
      expect(command).to contain %w[--page-size Letter]
      expect(command).to contain %w[--toc-l1-font-size 12]
      expect(command).to contain %w[--replace foo bar]
    end

    it "contains a specified by path argument" do
      pdfkit = PDFKit.new('html')
      command = pdfkit.command("/foo/bar")
      expect(command.first).to match(/wkhtmltopdf/)
      expect(command.last).to eq("/foo/bar")
    end

    it "contains a specified by path argument of Pathname" do
      pdfkit = PDFKit.new('html')
      command = pdfkit.command(Pathname.new("/foo/bar"))
      expect(command.first).to match(/wkhtmltopdf/)
      expect(command.last).to eq("/foo/bar")
    end

    it "sets up one cookie when hash has only one cookie" do
      pdfkit = PDFKit.new('html', cookie: {cookie_name: :cookie_value})
      command = pdfkit.command
      expect(command).to contain %w[--cookie cookie_name cookie_value]
    end

    it "does not split Windows paths that contain spaces" do
      pdfkit = PDFKit.new('html')
      allow(PDFKit.configuration).to receive(:wkhtmltopdf).and_return 'c:/Program Files/wkhtmltopdf/wkhtmltopdf.exe'
      expect(pdfkit.command).not_to contain(%w[c:/Program Files/wkhtmltopdf/wkhtmltopdf.exe])
    end

    it "does not shell escape source URLs" do
      pdfkit = PDFKit.new('https://www.google.com/search?q=pdfkit')
      expect(pdfkit.command).to include "https://www.google.com/search?q=pdfkit"
    end

    it "formats source for the command" do
      pdfkit = PDFKit.new('https://www.google.com/search?q=pdfkit')
      expect(pdfkit.source).to receive(:to_input_for_command)
      pdfkit.command
    end

    it "sets up multiple cookies when passed multiple cookies" do
      pdfkit = PDFKit.new('html', :cookie => {:cookie_name1 => :cookie_val1, :cookie_name2 => :cookie_val2})
      command = pdfkit.command
      expect(command).to contain %w[--cookie cookie_name1 cookie_val1]
      expect(command).to contain %w[--cookie cookie_name2 cookie_val2]
    end

    it "sets up multiple cookies when passed an array of tuples" do
      pdfkit = PDFKit.new('html', :cookie => [[:cookie_name1, :cookie_val1], [:cookie_name2, :cookie_val2]])
      command = pdfkit.command
      expect(command).to contain %w[--cookie cookie_name1 cookie_val1]
      expect(command).to contain %w[--cookie cookie_name2 cookie_val2]
    end

    it "will not include default options it is told to omit" do
      PDFKit.configure do |config|
        config.default_options[:disable_smart_shrinking] = true
      end

      pdfkit = PDFKit.new('html')
      expect(pdfkit.command).to include('--disable-smart-shrinking')
      pdfkit = PDFKit.new('html', :disable_smart_shrinking => false)
      expect(pdfkit.command).not_to include('--disable-smart-shrinking')
    end

    it "must not split string arguments containing spaces" do
      pdfkit = PDFKit.new('html', :header_center => "foo [page]")
      expect(pdfkit.command).to contain ['--header-center', 'foo [page]']
    end

    it "paramatarizes string arguments" do
      pdfkit = PDFKit.new('html', :header_center => "$(ls)")
      expect(pdfkit.command).to contain %w[--header-center $(ls)]
    end

    it "read the source from stdin if it is html" do
      pdfkit = PDFKit.new('html')
      command = pdfkit.command
      expect(command[-2]).to eq('-')
      expect(command[-1]).to eq('-')
    end

    it "specifies the URL to the source if it is a url" do
      pdfkit = PDFKit.new('http://google.com')
      command = pdfkit.command
      expect(command[-2]).to eq("http://google.com")
      expect(command[-1]).to eq("-")
    end

    it "does not break Windows paths" do
      pdfkit = PDFKit.new('html')
      allow(PDFKit.configuration).to receive(:wkhtmltopdf).and_return 'c:/Program Files/wkhtmltopdf/wkhtmltopdf.exe'
      expect(pdfkit.command).not_to contain ['Program', 'Files']
    end

    it "specifies the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      command = pdfkit.command
      expect(command[-2]).to eq(file_path)
      expect(command[-1]).to eq('-')
    end

    it "specifies the path to the source if it is a tempfile" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(Tempfile.new(file_path))
      command = pdfkit.command
      expect(command[-2]).to start_with(Dir.tmpdir)
      expect(command[-1]).to eq('-')
    end

    it "specifies the path for the ouput if a path is given" do
      file_path = "/path/to/output.pdf"
      pdfkit = PDFKit.new("html")
      command = pdfkit.command(file_path)
      expect(command.last).to eq(file_path)
    end

    it "detects special pdfkit meta tags" do
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
      expect(command).to contain %w[--page-size Legal]
      expect(command).to contain %w[--orientation Landscape]
    end

    it "detects cookies meta tag" do
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
      expect(command).to contain %w[--cookie rails_session rails_session_value --cookie cookie_variable cookie_variable_value]
    end

    it "detects disable_smart_shrinking meta tag" do
      body = %{
        <html>
          <head>
            <meta name="pdfkit-disable_smart_shrinking" content="true"/>
          </head>
        </html>
      }
      pdfkit = PDFKit.new(body)
      command = pdfkit.command
      expect(command).to include "--disable-smart-shrinking"
      expect(command).not_to contain %w[--disable-smart-shrinking true]
    end

    it "detects names with hyphens instead of underscores" do
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
      expect(pdfkit.command).not_to include 'name\='
    end

    it "detects special pdfkit meta tags despite bad markup" do
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
      expect(command).to contain %w[--page-size Legal]
      expect(command).to contain %w[--orientation Landscape]
    end

    it "skips non-pdfkit meta tags" do
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
      expect(command).not_to contain %w[--page-size Legal]
      expect(command).to contain %w[--orientation Landscape]
    end

    it "does not use quiet when told to" do
      pdfkit = PDFKit.new('html', quiet: false)
      expect(pdfkit.command).not_to include '--quiet'
    end

    it "uses quiet option by default" do
      pdfkit = PDFKit.new('html')
      expect(pdfkit.command).to include '--quiet'
    end

    it "does not use quiet option in verbose mode" do
      PDFKit.configure do |config|
        config.verbose = true
      end

      pdfkit = PDFKit.new('html')
      expect(pdfkit.command).not_to include '--quiet'

      PDFKit.configure do |config|
        config.verbose = false
      end
    end

    it "does not use quiet option in verbose mode when option of quiet is configured" do
      PDFKit.configure do |config|
        config.verbose = true
        config.default_options[:quiet] = true
      end

      pdfkit = PDFKit.new('html')
      expect(pdfkit.command).not_to include '--quiet'

      PDFKit.configure do |config|
        config.verbose = false
      end
    end

    it "does not use xvfb-run wrapper by default" do
      pdfkit = PDFKit.new('html')
      expect(pdfkit.command).not_to include 'xvfb-run'
    end

    it "uses xvfb-run wrapper when option of using xvfb is configured" do
      PDFKit.configure do |config|
        config.use_xvfb = true
      end

      pdfkit = PDFKit.new('html')
      expect(pdfkit.command).to include 'xvfb-run'

      PDFKit.configure do |config|
        config.use_xvfb = false
      end
    end

    context "on windows" do
      before do
        allow(PDFKit::OS).to receive(:host_is_windows?).and_return(true)
      end

      it "quotes spaces in options" do
        pdf = PDFKit.new('html', :title => 'hello world')
        expect(pdf.command).to contain ['--title', "hello world"]
      end
    end
  end

  describe "#to_pdf" do
    it "does not read the contents of the pdf when saving it as a file" do
      file_path = "/my/file/path.pdf"
      pdfkit = PDFKit.new('html', :page_size => 'Letter')

      mock_pdf = double
      expect(mock_pdf).to receive(:puts)
      expect(mock_pdf).not_to receive(:gets) # do no read the contents when given a file path
      expect(mock_pdf).to receive(:close_write)


      expect(IO).to receive(:popen) do |args, mode, &block|
        block.call(mock_pdf)
      end

      expect(::File).to receive(:size).with(file_path).and_return(50)

      pdfkit.to_pdf(file_path)
    end

    it "generates a PDF of the HTML" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      pdf = pdfkit.to_pdf
      expect(pdf[0...4]).to eq("%PDF") # PDF Signature at beginning of file
    end

    it "generates a PDF with a numerical parameter" do
      pdfkit = PDFKit.new('html', :header_spacing => 1)
      pdf = pdfkit.to_pdf
      expect(pdf[0...4]).to eq("%PDF") # PDF Signature at beginning of file
    end

    it "generates a PDF with a symbol parameter" do
      pdfkit = PDFKit.new('html', :page_size => :Letter)
      pdf = pdfkit.to_pdf
      expect(pdf[0...4]).to eq("%PDF") # PDF Signature at beginning of file
    end

    it "adds the stylesheet to the head tag if it has a head tag" do
      pdfkit = PDFKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      expect(pdfkit.source.to_s).to include("<style>#{File.read(css)}</style>")
    end

    it "prepends style tags if the HTML doesn't have a head tag" do
      pdfkit = PDFKit.new("<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      expect(pdfkit.source.to_s).to include("<style>#{File.read(css)}</style><html>")
    end

    it "throws an error if the source is not html and stylesheets have been added" do
      pdfkit = PDFKit.new('http://google.com')
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      expect { pdfkit.to_pdf }.to raise_error(PDFKit::ImproperSourceError)
    end

    it "can deal with ActiveSupport::SafeBuffer" do
      pdfkit = PDFKit.new(ActiveSupport::SafeBuffer.new "<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      expect(pdfkit.source.to_s).to include("<style>#{File.read(css)}</style></head>")
    end

    it "can deal with ActiveSupport::SafeBuffer if the HTML doesn't have a head tag" do
      pdfkit = PDFKit.new(ActiveSupport::SafeBuffer.new "<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      expect(pdfkit.source.to_s).to include("<style>#{File.read(css)}</style>")
    end

    it "escapes \\X in stylesheets" do
      pdfkit = PDFKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example_with_hex_symbol.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      expect(pdfkit.source.to_s).to include("<style>#{File.read(css)}</style></head>")
    end

    #NOTICE: This test is failed if use wkhtmltopdf-binary (0.9.9.1)
    it "throws an error if it is unable to connect" do
      pdfkit = PDFKit.new("http://google.com/this-should-not-be-found/404.html")
      expect { pdfkit.to_pdf }.to raise_error PDFKit::ImproperWkhtmltopdfExitStatus, /exitstatus=1/
    end

    it "does not throw an error if it is unable to connect", pending: 'this test works for wkhtmltopdf-binary (0.9.9.1)' do
      pdfkit = PDFKit.new("http://localhost/this-should-not-be-found/404.html")
      pdf = pdfkit.to_pdf
      expect(pdf[0...4]).to eq("%PDF") # PDF Signature at the beginning
    end

    it "generates a PDF if there are missing assets" do
      pdfkit = PDFKit.new("<html><body><img alt='' src='http://example.com/surely-it-doesnt-exist.gif' /></body></html>")
      pdf = pdfkit.to_pdf
      expect(pdf[0...4]).to eq("%PDF") # PDF Signature at the beginning
    end

    it "can handle ampersands in URLs" do
      pdfkit = PDFKit.new('https://www.google.com/search?q=pdfkit&sort=ASC')
      pdf = pdfkit.to_pdf
      expect(pdf[0...4]).to eq("%PDF") # PDF Signature at the beginning
    end
  end

  describe "#to_file" do
    before do
      @file_path = File.join(SPEC_ROOT,'fixtures','test.pdf')
      File.delete(@file_path) if File.exist?(@file_path)
    end

    after do
      File.delete(@file_path)
    end

    it "creates a file with the PDF as content" do
      pdfkit = PDFKit.new('html', :page_size => 'Letter')
      file = pdfkit.to_file(@file_path)
      expect(file).to be_instance_of(File)
      expect(File.read(file.path)[0...4]).to eq("%PDF") # PDF Signature at beginning of file
    end

    it "does not truncate data (in Ruby 1.8.6)" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = PDFKit.new(File.new(file_path))
      pdf_data = pdfkit.to_pdf
      pdfkit.to_file(@file_path)
      file_data = open(@file_path, 'rb') {|io| io.read }
      expect(pdf_data.size).to eq(file_data.size)
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

    it "does not allow shell injection in options" do
      pdfkit = PDFKit.new('html', :header_center => "a title\"; touch #{@test_path} #")
      pdfkit.to_pdf
      expect(File.exist?(@test_path)).to eq(false)
    end
  end
end
