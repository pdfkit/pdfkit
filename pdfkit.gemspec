# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pdfkit/version"

Gem::Specification.new do |s|
  s.name        = "pdfkit"
  s.version     = PDFKit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jared Pace", "Relevance"]
  s.email       = ["jared@codewordstudios.com"]
  s.homepage    = "http://github.com/jdpace/PDFKit"
  s.summary     = "HTML+CSS -> PDF"
  s.description = "Uses wkhtmltopdf to create PDFs using HTML"

  s.rubyforge_project = "pdfkit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Developmnet Dependencies
  s.add_development_dependency(%q<rspec>, ["~> 2.2.0"])
  s.add_development_dependency(%q<mocha>, [">= 0.9.10"])
  s.add_development_dependency(%q<rack-test>, [">= 0.5.6"])
  s.add_development_dependency(%q<activesupport>, [">= 3.0.8"])
end

