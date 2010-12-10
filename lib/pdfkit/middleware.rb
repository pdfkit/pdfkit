class PDFKit
  
  class Middleware
    
    def initialize(app, options = {}, conditions = {})
      @app = app
      @options = options
      @conditions = conditions
    end
        
    def call(env)
      @request = Rack::Request.new(env)
      
      status, headers, body = @app.call(env)
      
      if render_as_pdf?
        set_request_to_render_as_pdf(env)
        if headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
          body = PDFKit.new(translate_paths(body.first, env), @options).to_pdf
          
          # Do not cache PDFs
          headers.delete('ETag')
          headers.delete('Cache-Control')
          
          headers["Content-Length"] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
          headers["Content-Type"]   = "application/pdf"
        end
      end
      
      [status, headers, body]
    end
    
    private
    
      # Change relative paths to absolute
      def translate_paths(body, env)
        # Host with protocol
        root = "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
        
        body.gsub(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/, '\1=\2' + root + '\3\2')
      end
      
      def request_path_is_pdf?
        @request.path =~ /\.pdf$/
      end
      
      def render_as_pdf?
        if request_path_is_pdf? && @conditions[:only]
          rules = [@conditions[:only]].flatten
          rules.any? do |pattern|
            if pattern.is_a?(Regexp)
              @request.path =~ pattern
            else
              @request.path[0, pattern.length] == pattern
            end
          end
        else
          request_path_is_pdf?
        end
      end
      
      def set_request_to_render_as_pdf(env)
        path = Pathname(env['PATH_INFO'])
        ['PATH_INFO','REQUEST_URI'].each { |e| env[e] = path.to_s.sub(/#{path.extname}$/,'')  } if path.extname == '.pdf'
        env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      end
      
      def concat(accepts, type)
        (accepts || '').split(',').unshift(type).compact.join(',')
      end
  
  end
end
