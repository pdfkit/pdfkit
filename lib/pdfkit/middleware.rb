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
      @request    = Rack::Request.new(env)
      @render_pdf = false

      set_request_to_render_as_pdf(env) if render_as_pdf?
      status, headers, response = @app.call(env)

      if rendering_pdf? && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
        body = response.respond_to?(:body) ? response.body : response.join
        body = body.join if body.is_a?(Array)
        body = PDFKit.new(translate_paths(body, env), wkhtmltopdf_options(headers)).to_pdf
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

        headers['Content-Length']         = (body.respond_to?(:bytesize) ? body.bytesize : body.size).to_s
        headers['Content-Type']           = 'application/pdf'
      end

      [status, headers, response]
    end

    private

    # Change relative paths to absolute, and relative protocols to absolute protocols
    def translate_paths(body, env)
      body = translate_relative_paths(body, env)
      translate_relative_protocols(body, env)
    end

    def translate_relative_paths(body, env)
      root = PDFKit.configuration.root_url || "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
      # Try out this regexp using rubular http://rubular.com/r/hiAxBNX7KE
      body.gsub(/(href|src)=(['"])\/([^\/"']([^\"']*|[^"']*))?['"]/, "\\1=\\2#{root}\\3\\2")
    end

    def translate_relative_protocols(body, env)
      protocol = "#{env['rack.url_scheme']}://"
      # Try out this regexp using rubular http://rubular.com/r/0Ohk0wFYxV
      body.gsub(/(href|src)=(['"])\/\/([^\"']*|[^"']*)['"]/, "\\1=\\2#{protocol}\\3\\2")
    end

    def rendering_pdf?
      @render_pdf
    end

    def render_as_pdf?
      request_path = @request.path
      request_path_is_pdf = request_path.match(%r{\.pdf$})

      if request_path_is_pdf && @conditions[:only]
        conditions_as_regexp(@conditions[:only]).any? do |pattern|
          request_path =~ pattern
        end
      elsif request_path_is_pdf && @conditions[:except]
        conditions_as_regexp(@conditions[:except]).each do |pattern|
          return false if request_path =~ pattern
        end

        return true
      else
        request_path_is_pdf
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
      [conditions].flatten.map do |pattern|
        pattern.is_a?(Regexp) ? pattern : Regexp.new('^' + pattern)
      end
    end

    def wkhtmltopdf_options(headers)
      @options.merge(extract_response_options(headers))
    end

    def extract_response_options(headers)
      if headers.has_key?('wkhtmltopdf')
        begin
          JSON.parse(headers.delete('wkhtmltopdf'))
        rescue JSON::ParserError
          {}
        end
      else
        {}
      end
    end
  end
end
