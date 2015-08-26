require 'uri'

class PDFKit
  class Source
    SOURCE_FROM_STDIN = '-'

    def initialize(url_file_or_html)
      @source = url_file_or_html
    end

    def url?
      @is_url ||= @source.is_a?(String) && @source.match(/\Ahttp/)
    end

    def file?
      @is_file ||= @source.kind_of?(File)
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
      url_needs_escaping? ? URI::escape(@source) : @source
    end

    def url_needs_escaping?
      URI::decode(@source) == @source
    end
  end
end
