# frozen_string_literal: true

require 'tempfile'
require 'uri'

class PDFKit
  class Source
    SOURCE_FROM_STDIN = '-'

    def initialize(url_file_or_html)
      @source = url_file_or_html
      # @source is assumed to be modifiable, so make sure it is.
      @source = @source.dup if @source.is_a?(String) && @source.frozen?
    end

    def url?
      @is_url ||= @source.is_a?(String) && @source.match(/\Ahttp/)
    end

    def file?
      @is_file ||= @source.kind_of?(File) || @source.kind_of?(Tempfile)
    end

    def html?
      @is_html ||= !(url? || file?)
    end

    def to_input_for_command
      if file?
        @source.path
      elsif url?
        %{"#{shell_safe_url}"}
      else
        SOURCE_FROM_STDIN
      end
    end

    def to_s
      file? ? @source.path : @source
    end

    private

    def shell_safe_url
      url = url_needs_escaping? ? URI::DEFAULT_PARSER.escape(@source) : @source

      URI::DEFAULT_PARSER.parse(url)
      shellescape_query(url)
    end

    def url_needs_escaping?
      URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.unescape(@source)) != @source
    end

    def needs_shell_escaping?(data)
      Shellwords.escape(shellwords_unescape(data)) != data
    end

    def shellescape_query(url)
      url, query = url.split('?')
      return url.to_s if query.nil?

      params = query.split('&').map { |pv| pv.split('=') }
      params = params.map do |parameter_name, parameter_value|
        parameter_name  = shellescape_parameter_name(parameter_name) if needs_shell_escaping?(parameter_name)
        parameter_value = Shellwords.escape(parameter_value) if needs_shell_escaping?(parameter_value)

        [parameter_name, parameter_value]
      end.to_h

      query = params.map { |pv| pv.join('=') }.join('&')

      [url, query].join('?')
    end

    def shellescape_parameter_name(parameter_name)
      allow_curly_bracket_regex = %r{\\([\[\]])}

      Shellwords.escape(parameter_name).gsub(allow_curly_bracket_regex, '\1')
    end

    def shellwords_unescape(value)
      value.gsub(%r{\\([^A-Za-z0-9_\-.,:+\/@\n])}, '\1')
    end
  end
end
