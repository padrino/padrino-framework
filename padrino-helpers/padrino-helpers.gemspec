require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)
require 'rubygems'
require 'bundler'

Gem::Specification.new do |s|
  s.name = %q{padrino-helpers}
  s.rubyforge_project = %q{padrino-helpers}
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = %q{padrinorb@gmail.com}
  s.summary = %q{Helpers for padrino}
  s.homepage = %q{http://github.com/padrino/padrino-framework/tree/master/padrino-helpers}
  s.description = %q{Tag helpers, asset helpers, form helpers, form builders and many more helpers for padrino}
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino-helpers.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = 'lib'
  s.add_runtime_dependency(%q<padrino-core>, ["= #{Padrino.version}"])
  s.add_bundler_dependencies :helpers, :development
end