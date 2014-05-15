class PDFKit
  class Source
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
    
    def to_s
      if file?
        @source.path
      elsif url?
        escaped_url
      else
        @source
      end
    end

    private

    def escaped_url
      @source.gsub '&', '\\\\&'
    end
  end
end
