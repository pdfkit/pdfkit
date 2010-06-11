require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pdfkit"
    gem.summary = %Q{HTML+CSS -> PDF}
    gem.description = %Q{Uses wkhtmltopdf to create PDFs using HTML}
    gem.email = "jared@codewordstudios.com"
    gem.homepage = "http://github.com/jdpace/PDFKit"
    gem.authors = ["jdpace"]
    gem.add_dependency "activesupport"
    gem.add_development_dependency "rspec", "~> 2.0.0.beta.8"
    gem.add_development_dependency 'mocha'
    gem.files = [
      ".document",
       ".gitignore",
       "LICENSE",
       "README.md",
       "Rakefile",
       "VERSION",
       "bin/pdfkit.rb",
       "bin/wkhtmltopdf-linux-i386-0-9-9",
       "bin/wkhtmltopdf-osx-i386-0-9-9",
       "bin/wkhtmltopdf-proxy",
       "lib/pdfkit.rb",
       "lib/pdfkit/middleware.rb",
       "lib/pdfkit/pdfkit.rb",
       "lib/pdfkit/source.rb",
       "pdfkit.gemspec",
       "spec/pdfkit_spec.rb",
       "spec/source_spec.rb",
       "spec/fixtures/example.css",
       "spec/fixtures/example.html",
       "spec/spec.opts",
       "spec/spec_helper.rb"
    ]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
Rspec::Core::RakeTask.new(:spec) do |spec|
end

Rspec::Core::RakeTask.new(:rcov) do |spec|
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "PDFKit #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
