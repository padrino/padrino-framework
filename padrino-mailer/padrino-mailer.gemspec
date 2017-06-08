#!/usr/bin/env gem build
# encoding: utf-8

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
  s.license = "MIT"

  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.rdoc_options  = ["--charset=UTF-8"]

  s.add_dependency("padrino-core", Padrino.version)
  if RUBY_VERSION >= "2.0"
    s.add_dependency("mime-types")
  else
    s.add_dependency("mime-types", "< 3")
  end
  s.add_dependency("mail", "~> 2.5")
end
