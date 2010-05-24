class PDFKit
  
  # A rack middleware for validating HTML via w3c validator
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @options = options
    end
        
    def call(env)
      puts env.inspect
      
      status, headers, response = @app.call( env )
      
      request = Rack::Request.new( env )
      if !request.params['pdf'].blank?
        if headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
          body = response.body
          
          # Make absolute urls
          uri = env['REQUEST_URI'].split('?').first
          uri += '/' unless uri.match(/\/$/)
          root = env['rack.url_scheme'] + "://" + env['HTTP_HOST']
          # translate relative urls
          body.gsub!(/(href|src)=['"]([^\/][^\"']*)['"]/,'\1="'+root+'/\2"')
          
          # translate absolute urls
          body.gsub!(/(href|src)=['"]\/([^\"]*|[^']*)['"]/,'\1="'+uri+'\2"')
          
          pdf = PDFKit.new(body, @options)
          body = pdf.to_pdf
          
          headers["Content-Length"] = body.length.to_s
          headers["Content-Type"] = "application/pdf"
          response = [body]
        end
      end
      
      [status, headers, response]
    end
  
  end
end