# clean cache
def clean_cache
  PDFKit.send(:remove_const, 'Generator')
  load './lib/pdfkit/generator.rb'
end
# precondition methods assurance
def directories_up_precondition
  FileUtils.mkdir_p(@tmp_dir_path)
  File.directory?(@tmp_dir_path).should be_true
  FileUtils.mkdir_p(@default_dir_path)
  File.directory?(@default_dir_path).should be_true
end
def directories_down_precondition
  FileUtils.rm_rf(@default_dir_path)
  File.directory?(@default_dir_path).should be_false
  FileUtils.rm_rf(@tmp_dir_path)
  File.directory?(@tmp_dir_path).should be_false
end
def files_up_precondition
  File.exists?(@cover_path).should be_true
  File.exists?(@header_path).should be_true
  File.exists?(@footer_path).should be_true
end
# methods need for options_for_pdfkit and method print
def default_directory_path
  Pathname.new join('documents')
end
def temporary_directory_path
  Pathname.new File.join('printer')
end
def create_temporary_folder
  FileUtils.mkdir_p temporary_directory_path
end
def destroy_temporary_folder
  FileUtils.rm_rf temporary_directory_path
end
def path_to_document_cover_html_file
  Pathname.new File.join(temporary_directory_path, 'cover.html')
end
def path_to_document_header_html_file
  Pathname.new File.join(temporary_directory_path, 'header.html')
end
def path_to_document_body_html_file
  Pathname.new File.join(temporary_directory_path, 'body.html')
end
def path_to_document_footer_html_file
  Pathname.new File.join(temporary_directory_path, 'footer.html')
end
def path_to_document_pdf
  Pathname.new File.join(temporary_directory_path, 'document.pdf')
end
def path_to_css
  Pathname.new File.join(temporary_directory_path, 'license.css')
end
def delete_default_directory
  FileUtils.rm_rf default_directory_path
end
def create_document_cover_html_file
  File.open(path_to_document_cover_html_file, 'w') {|f| f.write(path_to_document_cover_html_file)}
end
def create_document_header_html_file
  File.open(path_to_document_header_html_file, 'w') {|f| f.write(path_to_document_header_html_file)}
end
def create_document_body_html_file
  File.open(path_to_document_body_html_file, 'w') {|f| f.write(path_to_document_body_html_file)}
end
def create_document_footer_html_file
  File.open(path_to_document_footer_html_file, 'w') {|f| f.write(path_to_document_footer_html_file)}
end
def create_document_css_file
  File.open(path_to_css, 'w') {|f| f.write(path_to_css)}
end