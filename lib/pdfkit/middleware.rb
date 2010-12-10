class PDFKit
  
  class Middleware
    
    def initialize(app, options = {}, conditions = {})
      @app = app
      @options = options
      @conditions = conditions
    end
    
    def call(env)
      @request = Rack::Request.new(env)
      set_request_to_render_as_pdf(env) if request_path_is_pdf?
      
      status, headers, response = @app.call(env)
      
      if render_as_pdf? && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.respond_to?(:body) ? response.body : response.join
        body = PDFKit.new(translate_paths(body, env), @options).to_pdf
        
        # Do not cache PDFs
        headers.delete('ETag')
        headers.delete('Cache-Control')
        
        headers["Content-Length"] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers["Content-Type"]   = "application/pdf"
      end
      
      [status, headers, body || response]
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
      %w[PATH_INFO REQUEST_URI].each { |e| env[e] = path.to_s.sub(/#{path.extname}$/,'') }
      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
    end
    
    def concat(accepts, type)
      (accepts || '').split(',').unshift(type).compact.join(',')
    end
    
  end
end
