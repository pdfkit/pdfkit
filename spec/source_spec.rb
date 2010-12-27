require 'spec_helper'

describe PDFKit::Source do
  
  describe "#url?" do
    it "should return true if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      source.should be_url
    end
    
    it "should return false if passed a file" do
      source = PDFKit::Source.new(File.new(__FILE__))
      source.should_not be_url
    end
    
    it "should return false if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      source.should_not be_url
    end

    it "should return false if passed HTML with embedded urls at the beginning of a line" do
      source = PDFKit::Source.new("<blink>Oh Hai!</blink>\nhttp://www.google.com")
      source.should_not be_url
    end
  end
  
  describe "#file?" do
    it "should return true if passed a file" do
      source = PDFKit::Source.new(File.new(__FILE__))
      source.should be_file
    end
    
    it "should return false if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      source.should_not be_file
    end
    
    it "should return false if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      source.should_not be_file
    end
  end
  
  describe "#html?" do
    it "should return true if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      source.should be_html
    end
    
    it "should return false if passed a file" do
      source = PDFKit::Source.new(File.new(__FILE__))
      source.should_not be_html
    end
    
    it "should return false if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      source.should_not be_html
    end
  end
  
  describe "#to_s" do
    it "should return the HTML if passed HTML" do
      source = PDFKit::Source.new('<blink>Oh Hai!</blink>')
      source.to_s.should == '<blink>Oh Hai!</blink>'
    end
    
    it "should return a path if passed a file" do
      source = PDFKit::Source.new(File.new(__FILE__))
      source.to_s.should == __FILE__
    end
    
    it "should return the url if passed a url like string" do
      source = PDFKit::Source.new('http://google.com')
      source.to_s.should == 'http://google.com'
    end
  end
  
end
