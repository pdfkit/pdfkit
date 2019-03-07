class PDFKit
  class Middleware
    def initialize(app, options = {}, conditions = {})
      @app        = app
      @options    = options
      @conditions = conditions
      @render_pdf = false
      @caching    = @conditions.delete(:caching) { false }
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @request    = Rack::Request.new(env)
      @render_pdf = false

      set_request_to_render_as_pdf(env) if render_as_pdf?
      status, headers, response = @app.call(env)

      if rendering_pdf? && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.respond_to?(:body) ? response.body : response.join
        body = body.join if body.is_a?(Array)

        root_url = root_url(env)
        protocol = protocol(env)
        options = @options.merge(root_url: root_url, protocol: protocol)

        if headers['PDFKit-javascript-delay']
          options.merge!(javascript_delay: headers.delete('PDFKit-javascript-delay').to_i)
        end

        body = PDFKit.new(body, options).to_pdf
        response = [body]

        if headers['PDFKit-save-pdf']
          File.open(headers['PDFKit-save-pdf'], 'wb') { |file| file.write(body) } rescue nil
          headers.delete('PDFKit-save-pdf')
        end

        unless @caching
          # Do not cache PDFs
          headers.delete('ETag')
          headers.delete('Cache-Control')
        end

        headers['Content-Length'] = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers['Content-Type']   = 'application/pdf'
        headers['Content-Disposition'] = @conditions[:disposition] || 'inline'
      end

      [status, headers, response]
    end

    private

    def root_url(env)
      PDFKit.configuration.root_url || "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
    end

    def protocol(env)
      env['rack.url_scheme']
    end

    def rendering_pdf?
      @render_pdf
    end

    def render_as_pdf?
      request_path = @request.path
      return false unless request_path.end_with?('.pdf')

      if @conditions[:only]
        conditions_as_regexp(@conditions[:only]).any? do |pattern|
          pattern === request_path
        end
      elsif @conditions[:except]
        conditions_as_regexp(@conditions[:except]).none? do |pattern|
          pattern === request_path
        end
      else
        true
      end
    end

    def set_request_to_render_as_pdf(env)
      @render_pdf = true

      path = @request.path.sub(%r{\.pdf$}, '')
      path = path.sub(@request.script_name, '')

      %w[PATH_INFO REQUEST_URI].each { |e| env[e] = path }

      env['HTTP_ACCEPT'] = concat(env['HTTP_ACCEPT'], Rack::Mime.mime_type('.html'))
      env['Rack-Middleware-PDFKit'] = 'true'
    end

    def concat(accepts, type)
      (accepts || '').split(',').unshift(type).compact.join(',')
    end

    def conditions_as_regexp(conditions)
      Array(conditions).map do |pattern|
        pattern.is_a?(Regexp) ? pattern : Regexp.new("^#{pattern}")
      end
    end
  end
end
