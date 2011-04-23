require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = "padrino-gen"
  s.rubyforge_project = "padrino-gen"
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = "padrinorb@gmail.com"
  s.summary = "Generators for easily creating and building padrino applications"
  s.homepage = "http://www.padrinorb.com"
  s.description = "Generators for easily creating and building padrino applications from the console"
  s.default_executable = "padrino-gen"
  s.executables = ["padrino-gen"]
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino-gen.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = "lib"
  s.add_dependency("padrino-core", Padrino.version)
  s.add_dependency("bundler", ">= 1.0.2")
  s.add_dependency("grit")
end
