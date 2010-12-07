require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = "padrino-mailer"
  s.rubyforge_project = "padrino-mailer"
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = "padrinorb@gmail.com"
  s.summary = "Mailer system for padrino"
  s.homepage = "http://www.padrinorb.com"
  s.description = "Mailer system for padrino allowing easy delivery of application emails"
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino-mailer.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = "lib"
  s.add_dependency("padrino-core", Padrino.version)
  s.add_dependency("mail", ">= 2.2.0")
  s.add_dependency("tlsmail") if RUBY_VERSION == "1.8.6"
end