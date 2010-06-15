require File.expand_path("../lib/padrino-core/version.rb", __FILE__)
require 'rubygems'
require 'bundler'

Gem::Specification.new do |s|
  s.name = "padrino-core"
  s.rubyforge_project = "padrino-core"
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = %q{padrinorb@gmail.com}
  s.summary = %q{The required Padrino core gem}
  s.homepage = "http://github.com/padrino/padrino-framework/tree/master/padrino-core"
  s.description = %q{The Padrino core gem required for use of this framework}
  s.default_executable = %q{padrino}
  s.executables = ["padrino"]
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino-core.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = 'lib'
  s.add_bundler_dependencies :core, :development
end