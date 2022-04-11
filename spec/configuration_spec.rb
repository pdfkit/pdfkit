# frozen_string_literal: true

require 'spec_helper'

describe PDFKit::Configuration do
  subject { PDFKit::Configuration.new }
  describe "#wkhtmltopdf" do
    context "when explicitly configured" do
      it "uses configured value and don't detect" do
        expect(subject).not_to receive(:default_wkhtmltopdf)
        subject.wkhtmltopdf = "./Gemfile" # Need a file which exists
        expect(subject.wkhtmltopdf).to eq("./Gemfile")
      end

      it "falls back to detected binary if configured path doesn't exists" do
        expect(subject).to receive(:default_wkhtmltopdf).twice.and_return("/bin/fallback")
        expect(subject).to receive(:warn).with(/No executable found/)
        subject.wkhtmltopdf = "./missing-file" # Need a file which doesn't exist
        expect(subject.wkhtmltopdf).to eq("/bin/fallback")
      end
    end

    context "when not explicitly configured" do
      context "when running inside bundler" do
        # Simulate the presence of bundler even if it's not here
        before { stub_const("Bundler::GemfileError", Class) }

        it "detects the existance of bundler" do
          expect(subject).to receive(:`).with('bundle exec which wkhtmltopdf').and_return("c:\\windows\\path.exe\n")
          expect(subject.wkhtmltopdf).to eq('c:\windows\path.exe')
        end

        it "falls back if bundler path fails" do
          # This happens when there is a wrong (buggy) version of bundler for example
          expect(subject).to receive(:`).with('bundle exec which wkhtmltopdf').and_return("")
          expect(subject).to receive(:`).with('which wkhtmltopdf').and_return("c:\\windows\\path.exe\n")
          expect(subject.wkhtmltopdf).to eq('c:\windows\path.exe')
        end

        it "returns last line of 'bundle exec which' output" do
          # Happens when the user does not have a HOME directory on their system and runs bundler < 2
          expect(subject).to receive(:`).with('bundle exec which wkhtmltopdf').and_return(<<~EOT
            `/home/myuser` is not a directory.
            Bundler will use `/tmp/bundler/home/myuser' as your home directory temporarily.
            /usr/bin/wkhtmltopdf
          EOT
          )
          expect(subject.wkhtmltopdf).to eq('/usr/bin/wkhtmltopdf')
        end
      end

      context "when running without bundler" do
        # Simulate the absence of bundler even if it's there
        before { hide_const("Bundler::GemfileError") }

        it "detects the existance of bundler" do
          expect(subject).not_to receive(:`).with('bundle exec which wkhtmltopdf')
          expect(subject).to receive(:`).with('which wkhtmltopdf').and_return('c:\windows\path.exe')
          expect(subject.wkhtmltopdf).to eq('c:\windows\path.exe')
        end
      end
    end
  end

  describe "#executable" do
    it "returns wkhtmltopdf by default" do
      expect(subject.executable).to eql subject.wkhtmltopdf
    end

    it "uses xvfb-run wrapper when option of using xvfb is configured" do
      expect(subject).to receive(:using_xvfb?).and_return(true)
      expect(subject.executable).to include 'xvfb-run'
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

    it "merges additional options with existing defaults" do
      subject.default_options = { quiet: false, is_awesome: true }
      expect(subject.default_options[:quiet]).to eql false
      expect(subject.default_options[:is_awesome]).to eql true
      expect(subject.default_options[:disable_smart_shrinking]).to eql false
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

  describe "#using_xvfb?" do
    it "can be configured to true" do
      subject.use_xvfb = true
      expect(subject.using_xvfb?).to eql true
    end

    it "defaults to false" do
      expect(subject.using_xvfb?).to eql false
    end

    it "can be configured to false" do
      subject.use_xvfb = false
      expect(subject.using_xvfb?).to eql false
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
