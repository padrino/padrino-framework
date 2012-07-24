#!/usr/bin/env gem build
# encoding: utf-8

require File.expand_path("../../padrino-core/lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'padrino-flash'
  s.version     = Padrino.version
  s.authors     = ['Benjamin Bloch']
  s.email       = ['cirex@gamesol.org']
  s.homepage    = 'https://github.com/Cirex/padrino-flash'
  s.description = 'A plugin for the Padrino web framework which adds support for Rails like flash messages'
  s.summary     = s.description
  s.date = Time.now.strftime("%Y-%m-%d")  

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.add_dependency("padrino-core", Padrino.version)

end