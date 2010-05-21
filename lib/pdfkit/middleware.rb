class PDFKit
  
  # A rack middleware for validating HTML via w3c validator
  class Middleware
    
    def initialize( app )
      @app = app
    end
        
    def call( env )
      status, headers, response = @app.call( env )
      
      request = Rack::Request.new( env )
      if !request.params['pdf'].blank?
        if headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
          body = response.body
        
          pdf = PDFKit.new(body)
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