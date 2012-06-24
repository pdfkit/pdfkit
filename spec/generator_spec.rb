require 'spec_helper'

describe PDFKit::Generator do
  subject {PDFKit.generator}
  before :all do
    @default_dir_path = File.join 'documents'
    @tmp_dir_path     = File.join 'pdfkit'
    @cover_path       = File.join @tmp_dir_path, 'cover_support_file.html'
    @header_path      = File.join @tmp_dir_path, 'header_support_file.html'
    @footer_path      = File.join @tmp_dir_path, 'footer_support_file.html'
  end
end