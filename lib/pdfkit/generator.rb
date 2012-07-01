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
        # injects the content necessary into the support files
        #   pdfkit uses to support its document creation
        #
        # @param [File]
        # @return [Nil]
        def temporary_files_injection(_cover_html_, _header_html_, _footer_html_)
          # if files were not created before
          temporary_files_creation
          # inject content
          File.open(temporary_file_paths[:cover], 'w')  {|f| f.write(_cover_html_)}
          File.open(temporary_file_paths[:header], 'w') {|f| f.write(_header_html_)}
          File.open(temporary_file_paths[:footer], 'w') {|f| f.write(_footer_html_)}

          nil
        end
        # deletes the temporary files used by pdfkit to support
        #   its document creation
        def temporary_files_deletion
          Dir.foreach(temporary_directory_path) do |f|
            File.delete(File.join(temporary_directory_path, f)) unless f == '.' or f == '..'
          end
        end
        # create pdfkit support environment
        def set_environment
          # create the files
          temporary_files_creation # required temporary directory will be created by the method call
        end
        # delete pdfkit support environment
        def unset_environment
          # remove temporary directory and all its contents
          # so no need to call pdf_kit_temporary_files_deletion
          temporary_directory_deletion
        end
        # options used by pdfkit for create the document
        #
        #  @param [Hash] _document_parts_ with the document different parts
        #  @param [Hash] _document_configurations_ with the document pages configurations
        #    - such as page size, margins, etc...
        #  @return [Hash] with the options to be set on to be generated pdf document
        def options_for_pdf_kit(_document_parts_, _document_configurations_)
          # inject the documents here
          _options = {}.merge(PDFKit.configuration.default_options)
          _options.merge!(_document_configurations_)
          _document_parts = _document_parts_[:header].instance_of?(Pathname) ? _document_parts_ : temporary_file_paths
          _options.merge!({
            :cover       => _document_parts[:cover],
            :header_html => _document_parts[:header],
            :footer_html => _document_parts[:footer],
            :title       => _document_parts_[:title]
          })
        end
        # return the document path to be used in the generation of the pdf file
        #
        # @param [String] _pdf_document_path_or_name_ with the desired name for the pdf document to be generated or
        #   the complete path for the pdf document to be generated
        # @raise [ArgumentError] when _pdf_document_path_or_name_ is not of type String or Pathname
        def document_path(_pdf_document_path_or_name_)
          # When _pdf_document_path_or_name_ is of type String or Pathname
          _argument_error_message = 'first argument should be the document full storage path of type Pathname or the document name'
          raise ArgumentError, _argument_error_message unless _pdf_document_path_or_name_.is_a? String or _pdf_document_path_or_name_.is_a? Pathname

          # create directory if it is not created before
          default_directory_creation

          # check if document name was given
          return _pdf_document_path_or_name_.to_s if _pdf_document_path_or_name_.include? default_directory_path

          File.join(default_directory_path, _pdf_document_path_or_name_)
        end
        # generates a pdf document out of html files, except body part that must be a string
        #
        # The difference between this method print and generate method is that of the document parts are passed as HTML FILES
        # and won't be therefore generated from HTML STRINGS auxiliar methods
        #
        # @param [String] _pdf_document_path_ indicating the place where to store the pdf generated file
        # @note use always .pdf extension in either full storage path or document name
        # @param [Hash] _options_ with the options to pdf kit including the different document parts html file paths
        # @param [Array] _stylesheet_path_ path where the stylesheet of the pdf document to be used is stored
        # @return [File] the pdf document file
        # @note generated pdf document file path can be obtained by using path method
        def print(_pdf_document_path_, _options_, _stylesheets_paths_)
          # instanciate pdf kit and create the generated contract file
          _body = _options_.delete(:body)
          _kit = PDFKit.new(_body, _options_)
          _stylesheets_paths_.each { |stylesheet| _kit.stylesheets << stylesheet }
          _kit.to_file(_pdf_document_path_) # contract pdf is generated by this call
        end
      end
  end
end