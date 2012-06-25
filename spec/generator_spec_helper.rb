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
def directory_path
  File.join('documents')
end
def temporary_path
  File.join('printer')
end
def create_temporary_folder
  FileUtils.mkdir_p temporary_path
end
def destroy_temporary_folder
  FileUtils.rm_rf temporary_path
end
def path_to_document_cover_html_file
  File.join(temporary_path, 'cover.html')
end
def path_to_document_header_html_file
  File.join(temporary_path, 'header.html')
end
def path_to_document_body_html_file
  File.join(temporary_path, 'body.html')
end
def path_to_document_footer_html_file
  File.join(temporary_path, 'footer.html')
end
def path_to_document_pdf
  Pathname.new(File.join(temporary_path, 'document.pdf'))
end
def delete_default_directory
  FileUtils.rm_rf directory_path
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