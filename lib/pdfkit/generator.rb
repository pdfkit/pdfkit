class PDFKit
  class << self
    def generator
      Generator.instance
    end
  end
  # The class provides methods for generating a pdf document
  # use PdfKit.generator.generate(...) to generate document
  #
  # Implements Singleton class Generator. You can retrieve singleton instance using method PdfKit.generator.
  #
  # @note wkhtmltopdf version I used can be downloaded by:
  #   - http://code.google.com/p/wkhtmltopdf/downloads/detail?name=wkhtmltopdf-0.9.9-OS-X.i368&can=2&q=
  # @note you can set the temporary support directory path to be used in pdf kit initialzer as:
  #   - :support_directory_path => desired directory path
  # @note you can set the default directory where generated pdf documents will be saved in pdf kit initializer as:
  #   - :default_directory_path => desired directory path
  #
  # @note This is a Singleton class and so cannot be instanciated more than once
  #
  # @author Frank Pimenta <frankapimenta@gmail.com>
  class Generator
    # make new method private to avoid class instanciation from outside
    private_class_method :new

    class << self
      def instance
        @__pdfkit_generator__ ||= new
      end
    end
  end
end