# clean cache
def clean_cache
  PDFKit.send(:remove_const, 'Generator')
  load './lib/pdfkit/generator.rb'
end
# precondition methods assurance
def directories_up_precondition
  FileUtils.mkdir_p(temporary_directory_path)
  File.directory?(temporary_directory_path).should be_true
  FileUtils.mkdir_p(default_directory_path)
  File.directory?(default_directory_path).should be_true
end
def directories_down_precondition
  FileUtils.rm_rf(default_directory_path)
  File.directory?(default_directory_path).should be_false
  FileUtils.rm_rf(temporary_directory_path)
  File.directory?(temporary_directory_path).should be_false
end
def files_up_precondition
  File.exists?(path_to_temporary_document_cover_html_file).should be_true
  File.exists?(path_to_temporary_document_header_html_file).should be_true
  File.exists?(path_to_temporary_document_footer_html_file).should be_true
end
# methods need for options_for_pdfkit and method print
def default_directory_path
  @default_directory_path ||= Pathname.new 'documents'
end
def temporary_directory_path
  @temporary_directory_path ||= Pathname.new 'pdfkit'
end
def create_temporary_folder
  FileUtils.mkdir_p temporary_directory_path
end
def destroy_temporary_folder
  FileUtils.rm_rf temporary_directory_path
end
def path_to_temporary_document_cover_html_file
  @path_to_temporary_document_cover_html_file ||= temporary_directory_path.join('cover_support_file.html')
end
def path_to_temporary_document_header_html_file
  @path_to_temporary_document_header_html_file ||= temporary_directory_path.join('header_support_file.html')
end
def path_to_temporary_document_footer_html_file
  @path_to_temporary_document_footer_html_file ||= temporary_directory_path.join('footer_support_file.html')
end
def path_to_document_cover_html_file
  @path_to_document_cover_html_file ||= temporary_directory_path.join('cover.html')
end
def path_to_document_header_html_file
  @path_to_document_header_html_file ||= temporary_directory_path.join('header.html')
end
def path_to_document_body_html_file
  @path_to_document_body_html_file ||= temporary_directory_path.join('body.html')
end
def path_to_document_footer_html_file
  @path_to_document_footer_html_file ||= temporary_directory_path.join('footer.html')
end
def path_to_document_pdf
  @path_to_document_pdf ||= temporary_directory_path.join('document.pdf')
end
def path_to_css
  @path_to_css ||= temporary_directory_path.join('license.css')
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
def set_pre_conditions
  create_temporary_folder
  create_document_cover_html_file
  create_document_header_html_file
  create_document_body_html_file
  create_document_footer_html_file
  create_document_css_file
end
def unset_pre_conditions
  destroy_temporary_folder
end