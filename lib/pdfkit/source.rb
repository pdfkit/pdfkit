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
        escaped_url
      else
        SOURCE_FROM_STDIN
      end
    end

    def to_s
      file? ? @source.path : @source
    end

    private

    def escaped_url
      url_needs_escaping? ? URI::DEFAULT_PARSER.escape(@source) : @source
    end

    def url_needs_escaping?
      URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.unescape(@source)) != @source
    end
  end
end
