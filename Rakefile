require 'rubygems'
require 'rake'
require 'bundler'
Bundler.require(:development)

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pdfkit"
    gem.summary = %Q{HTML+CSS -> PDF}
    gem.description = %Q{Uses wkhtmltopdf to create PDFs using HTML}
    gem.email = "jared@codewordstudios.com"
    gem.homepage = "http://github.com/jdpace/PDFKit"
    gem.authors = ["jdpace"]
    gem.add_development_dependency "rspec", "~> 2.0.0.beta.8"
    gem.add_development_dependency "rspec-core", "~> 2.0.0.beta.8"
    gem.add_development_dependency 'mocha'
    gem.post_install_message = File.read('POST_INSTALL')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
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
