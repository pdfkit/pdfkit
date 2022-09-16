# frozen_string_literal: true

require 'spec_helper'

describe PDFKit::Source do
  describe "#url?" do
    it "returns true if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source).to be_url
    end

    it "returns false if passed a file" do
      source = PDFKit::Source.new(File.new(__FILE__))
      expect(source).not_to be_url
    end

    it "returns false if passed a tempfile" do
      source = PDFKit::Source.new(::Tempfile.new(__FILE__))
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

    it "returns true if passed a tempfile" do
      source = PDFKit::Source.new(::Tempfile.new(__FILE__))
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

    it "returns false if passed a tempfile" do
      source = PDFKit::Source.new(::Tempfile.new(__FILE__))
      expect(source).not_to be_html
    end

    it "returns false if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source).not_to be_html
    end
  end

  describe "#to_input_for_command" do
    it "URI escapes source URLs and encloses them in quotes to accomodate ampersands" do
      source = PDFKit::Source.new("https://www.google.com/search?q='cat<dev/zero>/dev/null'")
      expect(source.to_input_for_command).to eq "\"https://www.google.com/search?q='cat%3Cdev/zero%3E/dev/null'\""
    end

    it "does not URI escape previously escaped source URLs" do
      source = PDFKit::Source.new("https://www.google.com/search?q='cat%3Cdev/zero%3E/dev/null'")
      expect(source.to_input_for_command).to eq "\"https://www.google.com/search?q='cat%3Cdev/zero%3E/dev/null'\""
    end

    it "returns a '-' for HTML strings to indicate that we send that content through STDIN" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source.to_input_for_command).to eq '-'
    end

    it "returns the file path for file sources" do
      source = PDFKit::Source.new(::File.new(__FILE__))
      expect(source.to_input_for_command).to match 'spec/source_spec.rb'
    end

    it "returns the file path for tempfile sources" do
      source = PDFKit::Source.new(file = ::Tempfile.new(__FILE__))
      expect(source.to_input_for_command).to match file.path
    end

    it "should not allow backtick shell execution in url" do
      filename = Dir::Tmpname.create('backtick_file') { |path| path }
      File.delete(filename) if File.file?(filename)

      source = PDFKit::Source.new("http://example.com/?name={'%20`sleep 5`'}")
      expect(source.to_input_for_command).to eq "\"http://example.com/?name={%27%20%60sleep%205%60%27}\""

      begin
        PDFKit.new("http%20`touch #{filename}`").to_pdf
      rescue URI::InvalidURIError
      end
      expect(File.file?(filename)).to eq false
    end

    it "should not allow $( shell execution in url" do
      filename = Dir::Tmpname.create('dolar_sign_file') { |path| path }
      File.delete(filename) if File.file?(filename)

      source = PDFKit::Source.new("http://example.com/?name={'%20$(sleep 5)'}")
      expect(source.to_input_for_command).to eq "\"http://example.com/?name={%27%20$(sleep%205)%27}\""

      begin
        PDFKit.new("http%20$(touch #{filename})").to_pdf
      rescue URI::InvalidURIError
      end
      expect(File.file?(filename)).to eq false
    end

    it "should not allow || shell execution in url" do
      filename = Dir::Tmpname.create('or_file') { |path| path }
      File.delete(filename) if File.file?(filename)

      source = PDFKit::Source.new("http://%20a\" || sleep 3; \"")
      expect { source.to_input_for_command }.to raise_exception(URI::InvalidURIError)

      begin
        PDFKit.new("http://%20a\" || touch #{filename}); \"").to_pdf
      rescue URI::InvalidURIError
      end
      expect(File.file?(filename)).to eq false
    end

    it "should not allow && shell execution in url" do
      filename = Dir::Tmpname.create('and_file') { |path| path }
      File.delete(filename) if File.file?(filename)

      source = PDFKit::Source.new("http://%20a\" && sleep 3; \"")
      expect { source.to_input_for_command }.to raise_exception(URI::InvalidURIError)

      begin
        PDFKit.new("http://%20a\" && touch #{filename}); \"").to_pdf
      rescue URI::InvalidURIError
      end
      expect(File.file?(filename)).to eq false
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

    it "returns a path if passed a tempfile" do
      source = PDFKit::Source.new(file = ::Tempfile.new(__FILE__))
      expect(source.to_s).to eq(file.path)
    end

    it "returns the url if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      expect(source.to_s).to eq('http://google.com')
    end
  end
end
