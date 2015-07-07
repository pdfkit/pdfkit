require 'spec_helper'

describe PDFKit::Source do
  describe "#new" do
    it "protects against shell attacks in URLs" do
      expect{ PDFKit::Source.new('https://google.com/search?q=pdfkit; do_something # --args') }.to raise_error URI::InvalidURIError
    end
  end

  describe "#url?" do
    it "returns true if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source).to be_url
    end

    it "returns false if passed a file" do
      source = PDFKit::Source.new(File.new(__FILE__))
      expect(source).not_to be_url
    end

    it "returns false if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source).not_to be_url
    end

    it "returns false if passed HTML with embedded urls at the beginning of a line" do
      source = PDFKit::Source.new("<blink>Oh Hai!</blink>\nhttp://www.google.com")
      expect(source).not_to be_url
    end
  end

  describe "#file?" do
    it "returns true if passed a file" do
      source = PDFKit::Source.new(::File.new(__FILE__))
      expect(source).to be_file
    end

    it "returns false if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source).not_to be_file
    end

    it "returns false if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source).not_to be_file
    end
  end

  describe "#html?" do
    it "returns true if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source).to be_html
    end

    it "returns false if passed a file" do
      source = PDFKit::Source.new(::File.new(__FILE__))
      expect(source).not_to be_html
    end

    it "returns false if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source).not_to be_html
    end
  end

  describe "#to_s" do
    it "returns the HTML if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source.to_s).to eq('<blink>Oh Hai!</blink>')
    end

    it "returns a path if passed a file" do
      source = PDFKit::Source.new(::File.new(__FILE__))
      expect(source.to_s).to eq(__FILE__)
    end

    it "returns the url if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source.to_s).to eq('http://google.com')
    end
  end
end
