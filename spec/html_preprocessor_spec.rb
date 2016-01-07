require 'spec_helper'

describe PDFKit::HTMLPreprocessor do
  describe "#process" do
    let(:preprocessor) { PDFKit::HTMLPreprocessor }
    let(:root_url) { 'http://example.com/' }  # This mirrors Middleware#root_url's response
    let(:protocol) { 'http' }

    it "correctly parses host-relative url with single quotes" do
      original_body = %{<html><head><link href='/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src="/test.png" /></body></html>}
      body = preprocessor.process original_body, root_url, protocol
      expect(body).to eq("<html><head><link href='http://example.com/stylesheets/application.css' media='screen' rel='stylesheet' type='text/css' /></head><body><img alt='test' src=\"http://example.com/test.png\" /></body></html>")
    end

    it "correctly parses host-relative url with double quotes" do
      original_body = %{<link href="/stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />}
      body = preprocessor.process original_body, root_url, protocol
      expect(body).to eq("<link href=\"http://example.com/stylesheets/application.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />")
    end

    it "correctly parses protocol-relative url with single quotes" do
      original_body = %{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>}
      body = preprocessor.process original_body, root_url, protocol
      expect(body).to eq("<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'>")
    end

    it "correctly parses protocol-relative url with double quotes" do
      original_body = %{<link href="//fonts.googleapis.com/css?family=Open+Sans:400,600" rel='stylesheet' type='text/css'>}
      body = preprocessor.process original_body, root_url, protocol
      expect(body).to eq("<link href=\"http://fonts.googleapis.com/css?family=Open+Sans:400,600\" rel='stylesheet' type='text/css'>")
    end

    it "correctly parses multiple tags where first one is root url" do
      original_body = %{<a href='/'><img src='/logo.jpg' ></a>}
      body = preprocessor.process original_body, root_url, protocol
      expect(body).to eq "<a href='http://example.com/'><img src='http://example.com/logo.jpg' ></a>"
    end

    it "returns the body even if there are no valid substitutions found" do
      original_body = "NO MATCH"
      body = preprocessor.process original_body, root_url, protocol
      expect(body).to eq("NO MATCH")
    end

    context 'when root_url is nil' do
      it "returns the body safely, without interpolating" do
        original_body = %{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'><a href='/'><img src='/logo.jpg'></a>}
        body = preprocessor.process original_body, nil, protocol
        expect(body).to eq(%{<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'><a href='/'><img src='/logo.jpg'></a>})
      end
    end

    context 'when protocol is nil' do
      it "returns the body safely, without interpolating" do
        original_body = %{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'><a href='/'><img src='/logo.jpg'></a>}
        body = preprocessor.process original_body, root_url, nil
        expect(body).to eq(%{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'><a href='http://example.com/'><img src='http://example.com/logo.jpg'></a>})
      end
    end

    context 'when root_url and protocol are both nil' do
      it "returns the body safely, without interpolating" do
        original_body = %{<link href='//fonts.googleapis.com/css?family=Open+Sans:400,600' rel='stylesheet' type='text/css'><a href='/'><img src='/logo.jpg'></a>}
        body = preprocessor.process original_body, nil, nil
        expect(body).to eq original_body
      end
    end
  end
end
