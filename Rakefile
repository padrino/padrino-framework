# rake bump[X.X.X] && rake publish

require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'
require 'fileutils'
require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

begin
  require 'sdoc'
rescue LoadError
  puts "You need to install sdoc: gem install sdoc for generate correctly ours api docs."
end

include FileUtils

ROOT        = File.expand_path(File.dirname(__FILE__))
GEM_NAME    = 'padrino-framework'

padrino_gems = [
  "padrino-core",
  "padrino-gen",
  "padrino-helpers",
  "padrino-mailer",
  "padrino-admin",
  "padrino"
]

GEM_PATHS = padrino_gems.freeze

def rake_command(command)
  sh "#{Gem.ruby} -S rake #{command}", :verbose => true
end

%w(install gemspec package).each do |name|
  desc "Run #{name} for all projects"
  task name do
    GEM_PATHS.each do |dir|
      Dir.chdir(dir) { rake_command(name) }
    end
  end
end

desc "Clean pkg and other stuff"
task :clean do
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) do
      %w(tmp pkg coverage).each { |dir| FileUtils.rm_rf dir }
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

desc "Commits all staged files"
task :commit, [:message] do |t, args|
  system(%Q[git commit -a -m "#{args.message}"])
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

desc "Executes a fresh install removing all padrino version and then reinstall all gems"
task :fresh => [:uninstall, :install, :clean]

desc "Pushes repository to GitHub"
task :push do
  puts "Pushing to github..."
  sh "git tag #{Padrino.version}"
  sh "git push origin master"
  sh "git push origin #{Padrino.version}"
end

desc "Release all padrino gems"
task :publish => :push do
  puts "Pushing to rubygems..."
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { rake_command("release") }
  end
  Rake::Task["clean"].invoke
end

desc "Run tests for all padrino stack gems"
task :test do
  # Omit the padrino metagem since no tests there
  GEM_PATHS[0..-2].each do |gem|
    # Hardcode the 'cd' into the command and do not use Dir.chdir because this causes random tests to fail
    sh "cd #{File.join(ROOT, gem)} && #{Gem.ruby} -S rake test", :verbose => true
  end
end

desc "Run tests for all padrino stack gems"
task :default => :test

desc "Generate documentation for the Padrino framework"
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
  rdoc.title    = "Padrino Framework Documentation"
  rdoc.main = 'padrino-core/README.rdoc'
  rdoc.rdoc_files.include('padrino-core/lib/{*.rb,padrino-core}/*.rb')
  rdoc.rdoc_files.include('padrino-core/lib/padrino-core/application/**/*.rb')
  rdoc.rdoc_files.exclude('padrino-core/lib/padrino-core/cli.rb')
  rdoc.rdoc_files.exclude('padrino-core/lib/padrino-core/support_lite.rb')
  rdoc.rdoc_files.exclude('padrino-core/lib/padrino-core/server.rb')
  rdoc.rdoc_files.include('padrino-core/README.rdoc')
  rdoc.rdoc_files.include('padrino-admin/lib/**/*.rb')
  rdoc.rdoc_files.exclude('padrino-admin/lib/padrino-admin/generators')
  rdoc.rdoc_files.include('padrino-admin/README.rdoc')
  rdoc.rdoc_files.include('padrino-helpers/lib/**/*.rb')
  rdoc.rdoc_files.include('padrino-helpers/README.rdoc')
  rdoc.rdoc_files.include('padrino-mailer/lib/**/*.rb')
  rdoc.rdoc_files.include('padrino-mailer/README.rdoc')
end

desc "Publish doc on padrino.github.com"
task :pdoc => :rdoc do
  puts "Publishing doc on padrinorb.com ..."
  Rake::SshDirPublisher.new("root@lipsiasoft.biz", "/mnt/www/apps/padrino/public/api", "doc").upload
  FileUtils.rm_rf "doc"
end