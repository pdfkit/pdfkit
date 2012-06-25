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

    private
      class << self
        # return the path where generated document files are going to be saved
        #
        # @return [Path] path where generated pdf file is to be saved
        #
        def default_directory_path
          @__default_directory_path__ ||= PDFKit.configuration.default_options[:default_directory_path] || File.join('documents')
        end
        # create the directory that will hold the generated pdf documents
        #
        # @return [Path] directory created for the generated pdf documents
        def default_directory_creation
          FileUtils.mkdir_p(default_directory_path)
        end
        # return the temporary path for pdf_kit files support
        #
        # @return [Path] temporary directory path to use for pdfkit environment
        def temporary_directory_path
          @__temporary_directory_path__ ||= PDFKit.configuration.default_options[:support_directory_path] || File.join('pdfkit')
        end
        # creates the temporary directory path where temporary html files
        #   created for pdf kit are be put
        #
        # @return [Fixnum]
        def temporary_directory_creation
          FileUtils.mkdir_p(temporary_directory_path)
        end
        # deletes the temporary directory path where temporary html files
        #   created for pdf kit were put
        #
        # @return [Fixnum]
        def temporary_directory_deletion
          FileUtils.rm_rf(temporary_directory_path)
        end
        # returns the pdf kit support files paths
        #
        # @return [Hash] with the support files paths
        def temporary_file_paths
          return @file_names_path unless @file_names_path.nil? || @file_names_path.empty?

          @file_names_path = {}
          %W{cover header footer}.each do |file_name|
            _file_path = File.join(temporary_directory_path, "#{file_name}_support_file.html")
            @file_names_path.merge!({"#{file_name}".to_sym => _file_path})
          end
          @file_names_path
        end
        # creates the support temporary files necessary to the creation
        #   of the document by pdfkit
        #
        # @note required directory will be created in case it does not exist yet
        def temporary_files_creation
          # if directory does not exist create it
          temporary_directory_creation

          # create the temporary files
          %W{cover header footer}.each do |file_name|
            File.open(temporary_file_paths[file_name.to_sym], 'w')
          end
        end
      end
  end
end