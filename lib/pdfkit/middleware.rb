class PDFKit
  
  class Middleware
    
    def initialize(app, options = {})
      @app = app
      @options = options
    end
        
    def call(env)
      @render_pdf = false
      set_request_to_render_as_pdf(env) if env['PATH_INFO'].match(/\.pdf$/)
      
      status, headers, response = @app.call(env)
      
      request = Rack::Request.new(env)
      if @render_pdf && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.body
        
        body = translate_paths(body, env)
        
        pdf = PDFKit.new(body, @options)
        body = pdf.to_pdf
        
        # Do not cache PDFs
        headers.delete('ETag')
        headers.delete('Cache-Control')
        
        headers["Content-Length"] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers["Content-Type"] = "application/pdf"
        
        response = [body]
      end
      
      [status, headers, response]
    end
    
    private
    
      # Change relative paths to absolute
      def translate_paths(body, env)
        # Host with protocol
        root = env['rack.url_scheme'] + "://" + env['HTTP_HOST'] + "/"
        
        body.gsub!(/(href|src)=['"]\/([^\"']*|[^"']*)['"]/,'\1="'+root+'\2"')
        
        return body
      end
    
      def set_request_to_render_as_pdf(env)
        @render_pdf = true

        path = Pathname(env['PATH_INFO'])
        ['PATH_INFO','REQUEST_URI'].each { |e| env[e] = path.to_s.sub(/#{path.extname}$/,'')  } if path.extname == '.pdf'
        env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      end
      
      def concat(accepts, type)
        (accepts || '').split(',').unshift(type).compact.join(',')
      end
  
  end
end
