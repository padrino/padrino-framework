# rake bump[X.X.X] && rake publish
require 'rubygems'  unless defined?(Gem)
require 'fileutils' unless defined?(FileUtils)
require 'rake'
require 'yard'
require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

ROOT     = File.expand_path(File.dirname(__FILE__))
GEM_NAME = 'padrino-framework'

padrino_gems = %w[
  padrino-core
  padrino-gen
  padrino-helpers
  padrino-mailer
  padrino-admin
  padrino-cache
  padrino
]

GEM_PATHS = padrino_gems.freeze

def sh_rake(command)
  sh "#{Gem.ruby} -S rake #{command}", :verbose => true
end

def say(text, color=:magenta)
  n = { :bold => 1, :red => 31, :green => 32, :yellow => 33, :blue => 34, :magenta => 35 }.fetch(color, 0)
  puts "\e[%dm%s\e[0m" % [n, text]
end

desc "Run 'install' for all projects"
task :install do
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { sh_rake(:install) }
  end
end

desc "Clean pkg and other stuff"
task :clean do
  GEM_PATHS.each do |g|
    %w[tmp pkg coverage].each { |dir| sh 'rm -rf %s' % File.join(g, dir) }
  end
end

desc "Clean pkg and other stuff"
task :uninstall do
  sh "gem search --no-version padrino | grep padrino | xargs gem uninstall -a"
end

desc "Displays the current version"
task :version do
  say "Current version: #{Padrino.version}"
end

desc "Bumps the version number based on given version"
task :bump, [:version] do |t, args|
  raise "Please specify version=x.x.x !" unless args.version
  version_path = File.dirname(__FILE__) + '/padrino-core/lib/padrino-core/version.rb'
  version_text = File.read(version_path).sub(/VERSION = '[a-z0-9\.]+'/, "VERSION = '#{args.version}'")
  say "Updating Padrino to version #{args.version}"
  File.open(version_path, 'w') { |f| f.write version_text }
  sh 'git commit -am "Bumped version to %s"' % args.version
end

desc "Executes a fresh install removing all padrino version and then reinstall all gems"
task :fresh => [:uninstall, :install, :clean]

desc "Pushes repository to GitHub"
task :push do
  say "Updating and verifying submodules"
  sh "git submodule foreach git pull origin master"
  sh "ls padrino-gen/lib/padrino-gen/generators/templates/static/README.rdoc"
  say "Pushing to github..."
  sh "git tag #{Padrino.version}"
  sh "git push origin master"
  sh "git push origin #{Padrino.version}"
end

desc "Release all padrino gems"
task :publish => :push do
  say "Pushing to rubygems..."
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { sh_rake("release") }
  end
  Rake::Task["clean"].invoke
end
task :release => :publish

desc "Run tests for all padrino stack gems"
task :test do
  # Omit the padrino metagem since no tests there
  GEM_PATHS[0..-2].each do |g|
    # Hardcode the 'cd' into the command and do not use Dir.chdir because this causes random tests to fail
    sh "cd #{File.join(ROOT, g)} && #{Gem.ruby} -S rake test"
  end
end

desc "Run tests for all padrino stack gems"
task :default => :test

desc "Generate documentation for the Padrino framework"
task :doc do
  YARD::CLI::Yardoc.new.run
end

desc "Publish doc on padrinorb.com/api"
task :pdoc => :doc do
  say "Publishing doc on padrinorb.com ..."
  sh "scp -r doc/* root@lps2.lipsiasoft.com:/mnt/www/apps/padrino/public/api/"
  sh "rm -rf doc"
end
