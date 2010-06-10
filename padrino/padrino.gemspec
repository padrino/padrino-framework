# -*- encoding: utf-8 -*-
require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{padrino}
  s.rubyforge_project = %q{padrino}
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = %q{padrinorb@gmail.com}
  s.summary = %q{The Godfather of Sinatra}
  s.version = "0.9.10"
  s.homepage = %q{http://github.com/padrino/padrino-framework}
  s.description = %q{The Godfather of Sinatra provides a full-stack agnostic framework on top of Sinatra}
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = 'lib'
  s.add_development_dependency(%q<haml>, [">= 2.2.1"])
  s.add_development_dependency(%q<shoulda>, [">= 2.10.3"])
  s.add_development_dependency(%q<mocha>, [">= 0.9.7"])
  s.add_development_dependency(%q<rack-test>, [">= 0.5.0"])
  s.add_development_dependency(%q<webrat>, [">= 0.5.1"])
  s.add_runtime_dependency(%q<padrino-core>, ["= #{Padrino.version}"])
  s.add_runtime_dependency(%q<padrino-helpers>, ["= #{Padrino.version}"])
  s.add_runtime_dependency(%q<padrino-mailer>, ["= #{Padrino.version}"])
  s.add_runtime_dependency(%q<padrino-gen>, ["= #{Padrino.version}"])
  s.add_runtime_dependency(%q<padrino-admin>, ["= #{Padrino.version}"])
end