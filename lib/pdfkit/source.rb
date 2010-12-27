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
      file? ? @source.path : @source
    end
  end
end
