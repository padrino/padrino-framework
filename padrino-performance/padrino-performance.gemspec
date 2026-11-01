#!/usr/bin/env gem build
# encoding: utf-8

require File.expand_path('lib/padrino-performance/version.rb', __dir__)

Gem::Specification.new do |s|
  s.name = 'padrino-performance'
  s.authors = ['Padrino Team', 'Nathan Esquenazi', "Davide D'Agostino", 'Arthur Chiu', 'Florian Gilcher', 'Darío Javier Cravero', 'Igor Bochkariov']
  s.email = 'padrinorb@gmail.com'
  s.summary = 'A gem for finding performance problems in Padrino'
  s.homepage = 'https://padrinorb.com'
  s.description = 'A gem for finding performance problems in Padrino by tracking loads and memory consumption.'
  s.required_ruby_version = '>= 2.7.8'
  s.required_rubygems_version = '>= 1.3.6'
  s.version = Padrino::Performance.version
  s.license = 'MIT'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/padrino/padrino-framework/issues',
    'changelog_uri' => 'https://github.com/padrino/padrino-framework/blob/master/CHANGES.rdoc',
    'documentation_uri' => 'https://padrinorb.com/guides/',
    'source_code_uri' => 'https://github.com/padrino/padrino-framework'
  }

  s.extra_rdoc_files = Dir['*.rdoc']
  s.files         = `git ls-files`.split("\n")
  s.executables   = ['padrino-performance']
  s.require_paths = ['lib']
  s.rdoc_options  = ['--charset=UTF-8']
end
