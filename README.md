# PDFKit

Create PDFs using plain old HTML+CSS. Uses [wkhtmltopdf](http://github.com/antialize/wkhtmltopdf) on the backend which renders HTML using Webkit.

## Install

### PDFKit

    gem install pdfkit

### wkhtmltopdf
 * **Automatic**: `sudo pdfkit --install-wkhtmltopdf`  
 install latest version into /usr/local/bin  
 (overwrite defaults with e.g. ARCHITECTURE=amd64 TO=/home/foo/bin)
 * By hand: http://code.google.com/p/wkhtmltopdf/downloads/list

## Usage
    
    # PDFKit.new takes the HTML and any options for wkhtmltopdf
    # run `wkhtmltopdf --extended-help` for a full list of options
    kit = PDFKit.new(html, :page_size => 'Letter')
    kit.stylesheets << '/path/to/css/file'
    
    # Git an inline PDF
    pdf = kit.to_pdf
    
    # Save the PDF to a file
    file = kit.to_file('/path/to/save/pdf')
    
    # PDFKit.new can optionally accept a URL or a File.
    # Stylesheets can not be added when source is provided as a URL of File.
    kit = PDFKit.new('http://google.com')
    kit = PDFKit.new(File.new('/path/to/html'))

    # Add any kind of option through meta tags
    PDFKit.new('<html><head><meta name="pdfkit-page_size" content="Letter")
    
## Configuration

If you're on Windows or you installed wkhtmltopdf by hand to a location other than /usr/local/bin you will need to tell PDFKit where the binary is. You can configure PDFKit like so:

    # config/initializers/pdfkit.rb
    PDFKit.configure do |config|
      config.wkhtmltopdf = '/path/to/wkhtmltopdf'
      config.default_options = {
        :page_size => 'Legal',
        :print_media_type => true
      }
    end

## Middleware

PDFKit comes with a middleware that allows users to get a PDF view of any page on your site by appending .pdf to the URL.

### Middleware Setup

**Non-Rails Rack apps**
   
    # in config.ru
    require 'pdfkit'
    use PDFKit::Middleware
    
**Rails apps**

    # in application.rb(Rails3) or environment.rb(Rails2)
    require 'pdfkit'
    config.middleware.use PDFKit::Middleware
    
**With PDFKit options**

    # options will be passed to PDFKit.new
    config.middleware.use PDFKit::Middleware, :print_media_type => true

## TODO
 - add amd64 support in --install-wkhtmltopdf

## Note on Patches/Pull Requests
 
* Fork the project.
* Setup your development environment with: gem install bundler; bundle install
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Jared Pace. See LICENSE for details.
