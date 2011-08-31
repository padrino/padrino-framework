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

desc "Run 'install' for all projects"
task :install do
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { sh_rake(:install) }
  end
end

desc "Clean pkg and other stuff"
task :clean do
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) do
      %w[tmp pkg coverage].each { |dir| FileUtils.rm_rf dir }
    end
  end
  Dir["**/*.gem"].each { |gem| FileUtils.rm_rf gem }
end

desc "Clean pkg and other stuff"
task :uninstall do
  sh "gem search --no-version padrino | grep padrino | xargs gem uninstall -a"
end

desc "Displays the current version"
task :version do
  puts "Current version: #{Padrino.version}"
end

desc "Bumps the version number based on given version"
task :bump, [:version] do |t, args|
  raise "Please specify version=x.x.x !" unless args.version
  version_path = File.dirname(__FILE__) + '/padrino-core/lib/padrino-core/version.rb'
  version_text = File.read(version_path).sub(/VERSION = '[\d\.]+'/, "VERSION = '#{args.version}'")
  puts "Updating Padrino to version #{args.version}"
  File.open(version_path, 'w') { |f| f.puts version_text }
  Rake::Task['commit'].invoke("Bumped version to #{args.version.to_s}")
end

desc "Commits all staged files"
task :commit, [:message] do |t, args|
  sh %Q{git commit -a -m "#{args.message}"}
end

desc "Executes a fresh install removing all padrino version and then reinstall all gems"
task :fresh => [:uninstall, :install, :clean]

desc "Pushes repository to GitHub"
task :push do
  puts "Updating submodules"
  sh "git submodule foreach git pull"
  puts "Pushing to github..."
  sh "git tag #{Padrino.version}"
  sh "git push origin master"
  sh "git push origin #{Padrino.version}"
end

desc "Release all padrino gems"
task :publish => :push do
  puts "Pushing to rubygems..."
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { sh_rake("release") }
  end
  Rake::Task["clean"].invoke
end

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
  yard = YARD::CLI::Yardoc.new
  yard.parse_arguments *%w[
    --exclude /support_lite|padrino-tasks|padrino-core\/cli/
    --hide-void-return
    --output-dir doc/
    --readme README.rdoc
    --no-private
    --title Padrino Framework
    padrino-*/lib/**/*.rb
  ]
  yard.run
end

desc "Publish doc on padrinorb.com/api"
task :pdoc => :doc do
  puts "Publishing doc on padrinorb.com ..."
  sh "scp -r doc/* root@srv2.lipsiasoft.biz:/mnt/www/apps/padrino/public/api/"
  FileUtils.rm_rf "doc"
end
