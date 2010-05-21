require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "PDFKit"
    gem.summary = %Q{HTML+CSS -> PDF}
    gem.description = %Q{Uses wkhtmltopdf to create PDFs using HTML}
    gem.email = "jared@codewordstudios.com"
    gem.homepage = "http://github.com/jdpace/PDFKit"
    gem.authors = ["jdpace"]
    gem.add_dependency "activesupport"
    gem.add_development_dependency "rspec", "~> 2.0.0.beta.8"
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
