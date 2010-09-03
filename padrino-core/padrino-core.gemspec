require File.expand_path("../lib/padrino-core/version.rb", __FILE__)

Gem::Specification.new do |s|
  s.name = "padrino-core"
  s.rubyforge_project = "padrino-core"
  s.authors = ["Padrino Team", "Nathan Esquenazi", "Davide D'Agostino", "Arthur Chiu"]
  s.email = "padrinorb@gmail.com"
  s.summary = "The required Padrino core gem"
  s.homepage = "http://www.padrinorb.com"
  s.description = "The Padrino core gem required for use of this framework"
  s.default_executable = "padrino"
  s.executables = ["padrino"]
  s.required_rubygems_version = ">= 1.3.6"
  s.version = Padrino.version
  s.date = Time.now.strftime("%Y-%m-%d")
  s.extra_rdoc_files = Dir["*.rdoc"]
  s.files = %w(.document .gitignore LICENSE README.rdoc Rakefile padrino-core.gemspec) + Dir.glob("{bin,lib,test}/**/*")
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_path = "lib"
  s.add_dependency("sinatra", ">= 1.0.0")
  s.add_dependency("http_router", ">= 0.3.15")
  s.add_dependency("thor", ">= 0.13.0")
  # If you want try our test on AS edge.
  # $ AS=edge rake test
  if ENV['AS'] == "edge"
    s.add_dependency("activesupport", ">= 3.0.0.beta4")
    s.add_dependency("tzinfo")
  else
    s.add_dependency("activesupport", ">= 2.3.8")
  end
end
