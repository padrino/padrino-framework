# -*- encoding: utf-8 -*-

require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{padrino-cache}
  s.rubyforge_project = %q{padrino-cache}
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = %q{padrinorb@gmail.com}
  s.summary = %q{Page and fragment caching for Padrino}
  s.homepage = %q{http://github.com/padrino/padrino-framework/tree/master/padrino-cache}
  s.description = %q{Caching support for memcached, page and fragment}
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino-cache.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = 'lib'
  s.add_runtime_dependency(%q<sinatra>, [">= 0.9.2"])
  s.add_runtime_dependency(%q<padrino-core>, ["= #{Padrino.version}"])
  s.add_development_dependency(%q<haml>, [">= 2.2.1"])
  s.add_development_dependency(%q<shoulda>, [">= 0"])
  s.add_development_dependency(%q<mocha>, [">= 0.9.7"])
  s.add_development_dependency(%q<rack-test>, [">= 0.5.0"])
  s.add_development_dependency(%q<webrat>, [">= 0.5.1"])
end