# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pdfkit/version"

Gem::Specification.new do |s|
  s.name        = "pdfkit"
  s.version     = PDFKit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jared Pace", "Relevance"]
  s.email       = ["jared@codewordstudios.com"]
  s.homepage    = "https://github.com/pdfkit/pdfkit"
  s.summary     = "HTML+CSS -> PDF"
  s.description = "Uses wkhtmltopdf to create PDFs using HTML"
  s.license     = "MIT"

  s.rubyforge_project = "pdfkit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.requirements << "wkhtmltopdf"

  # Development Dependencies
  s.add_development_dependency(%q<activesupport>, ["= 5.0.0.1"])
  s.add_development_dependency(%q<mocha>, [">= 0.9.10"])
  s.add_development_dependency(%q<rack-test>, ["0.6.3"])
  s.add_development_dependency(%q<i18n>, ["~> 0.7"]) # Ruby 1.9.2 compatibility
  s.add_development_dependency(%q<rake>, ["11.3.0"])
  s.add_development_dependency(%q<rdoc>, ["~> 4.0.1"])
  s.add_development_dependency(%q<rspec>, ["~> 3.0"])
end
