require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = "padrino"
  s.rubyforge_project = "padrino"
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = "padrinorb@gmail.com"
  s.summary = "The Godfather of Sinatra"
  s.homepage = "http://www.padrinorb.com"
  s.description = "The Godfather of Sinatra provides a full-stack agnostic framework on top of Sinatra"
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = "lib"
  s.add_dependency("padrino-core",    Padrino.version)
  s.add_dependency("padrino-helpers", Padrino.version)
  s.add_dependency("padrino-mailer",  Padrino.version)
  s.add_dependency("padrino-gen",     Padrino.version)
  s.add_dependency("padrino-cache",   Padrino.version)
  s.add_dependency("padrino-admin",   Padrino.version)
end