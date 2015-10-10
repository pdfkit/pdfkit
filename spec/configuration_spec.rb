require 'spec_helper'

describe PDFKit::Configuration do
  subject { PDFKit::Configuration.new }
  describe "#wkhtmltopdf" do
    context "when not explicitly configured" do
      it "detects the existance of bundler" do
        # Test assumes bundler is installed in your test environment
        expect(subject).to receive(:`).with('bundle exec which wkhtmltopdf').and_return('c:\windows\path.exe')
        subject.wkhtmltopdf
      end
    end
  end

  describe "#default_options" do
    it "sets defaults for the command options" do
      expect(subject.default_options[:disable_smart_shrinking]).to eql false
      expect(subject.default_options[:quiet]).to eql true
      expect(subject.default_options[:page_size]).to eql 'Letter'
      expect(subject.default_options[:margin_top]).to eql '0.75in'
      expect(subject.default_options[:margin_bottom]).to eql '0.75in'
      expect(subject.default_options[:margin_right]).to eql '0.75in'
      expect(subject.default_options[:margin_left]).to eql '0.75in'
      expect(subject.default_options[:encoding]).to eql 'UTF-8'
    end

    it "allows additional options to be configured" do
      subject.default_options = { quiet: false, is_awesome: true }
      expect(subject.default_options[:quiet]).to eql false
      expect(subject.default_options[:is_awesome]).to eql true
    end
  end

  describe "#root_url" do
    it "has no default" do
      expect(subject.root_url).to be_nil
    end

    it "is configurable" do
      subject.root_url = 'https://arbitrary.base_url.for/middleware'
      expect(subject.root_url).to eql 'https://arbitrary.base_url.for/middleware'
    end
  end

  describe "#meta_tag_prefix" do
    it "defaults to 'pdfkit-'" do
      expect(subject.meta_tag_prefix).to eql 'pdfkit-'
    end

    it "is configurable" do
      subject.meta_tag_prefix = 'aDifferentPrefix-'
      expect(subject.meta_tag_prefix).to eql 'aDifferentPrefix-'
    end
  end

  describe "#verbose?" do
    it "can be configured to true" do
      subject.verbose = true
      expect(subject.verbose?).to eql true
    end

    it "defaults to false" do
      expect(subject.verbose?).to eql false
    end

    it "can be configured to false" do
      subject.verbose = false
      expect(subject.verbose?).to eql false
    end
  end

  describe "#quiet?" do
    it "can be configured to true" do
      subject.verbose = false
      expect(subject.quiet?).to eql true
    end

    it "defaults to true" do
      expect(subject.quiet?).to eql true
    end

    it "can be configured to false" do
      subject.verbose = true
      expect(subject.quiet?).to eql false
    end
  end
end
