#!/usr/bin/env gem build
# encoding: utf-8

require File.expand_path('../padrino-core/lib/padrino-core/version.rb', __dir__)

Gem::Specification.new do |s|
  s.name = 'padrino-cache'
  s.authors = ['Padrino Team', 'Nathan Esquenazi', "Davide D'Agostino", 'Arthur Chiu']
  s.email = 'padrinorb@gmail.com'
  s.summary = 'Page and fragment caching for Padrino'
  s.homepage = 'https://padrinorb.com'
  s.description = 'Caching support for memcached, page and fragment'
  s.required_ruby_version = '>= 2.7.8'
  s.required_rubygems_version = '>= 1.3.6'
  s.version = Padrino.version
  s.license = 'MIT'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/padrino/padrino-framework/issues',
    'changelog_uri' => 'https://github.com/padrino/padrino-framework/blob/master/CHANGES.rdoc',
    'documentation_uri' => 'https://padrinorb.com/guides/',
    'source_code_uri' => 'https://github.com/padrino/padrino-framework'
  }

  s.extra_rdoc_files = Dir['*.rdoc']
  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.rdoc_options  = ['--charset=UTF-8']

  s.add_runtime_dependency('padrino-core', Padrino.version)
  s.add_runtime_dependency('padrino-helpers', Padrino.version)
  s.add_runtime_dependency('moneta', ['~> 1.6'])
end
