class PDFKit
  class Source
    SOURCE_FROM_STDIN = '-'

    def initialize(url_file_or_html)
      @source = url_file_or_html
    end

    def url?
      @source.is_a?(String) && @source.match(/\Ahttp/)
    end

    def file?
      @source.kind_of?(File)
    end

    def html?
      !(url? || file?)
    end

    def to_input_for_command
      if file?
        @source.path
      elsif url?
        URI::escape(@source)
      else
        SOURCE_FROM_STDIN
      end
    end

    def to_s
      file? ? @source.path : @source
    end
  end
end
