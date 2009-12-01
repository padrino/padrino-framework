# Simple release is: rake version:bump:minor publish

require 'pathname'
require "rake/clean"
require "rake/gempackagetask"
require 'fileutils'
require File.dirname(__FILE__) + '/versioner'

include FileUtils

ROOT = Pathname(__FILE__).dirname.expand_path
GEM_NAME = 'padrino-framework'
GEM_VERSION = ROOT.join('VERSION').read.chomp
VERSIONER = Versioner.new(GEM_VERSION, Dir[File.dirname(__FILE__) + '/**/VERSION'])

padrino_gems = [
  "padrino-core",
  "padrino-cache",
  "padrino-admin",
  "padrino-gen",
  "padrino-helpers",
  "padrino-mailer",
  "padrino-routing",
  "padrino"
]

GEM_PATHS = padrino_gems.freeze

def rake_command(command)
  sh "#{Gem.ruby} -S rake #{command}", :verbose => true
end

%w(install gemspec build).each do |task_name|
  desc "Run #{task_name} for all projects"
  task task_name do
    GEM_PATHS.each do |dir|
      Dir.chdir(dir) { rake_command(task_name) }
    end
  end
end

desc "Clean pkg and other stuff"
task :clean do
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) do
      FileUtils.rm_rf "doc"
      FileUtils.rm_rf "tmp"
      FileUtils.rm_rf "pkg"
    end
  end
end

desc "Clean pkg and other stuff"
task :uninstall do
  GEM_PATHS.each do |gem|
    sh "gem uninstall #{gem} -a"
  end
end

desc "Displays the current version"
task :version do
  puts "Current version: #{VERSIONER.current_version}"
end

desc "Commits all staged files"
task :commit, [:message] do |t, args|
  system("git commit -a -m \"#{args.message}\"")
end

namespace :version do
  namespace :bump do
    desc "Bump the gemspec by a major version."
    task :major => :versionomy do
      version = VERSIONER.bump!(:major)
      puts "Bumping the major version to #{version.to_s}"
      Rake::Task['gemspec'].invoke
      Rake::Task['commit'].invoke("Bumped version to #{version.to_s}")
    end

    desc "Bump the gemspec by a minor version."
    task :minor => :versionomy do
      version = VERSIONER.bump!(:minor)
      puts "Bumping the minor version to #{version.to_s}"
      Rake::Task['gemspec'].invoke
      Rake::Task['commit'].invoke("Bumped version to #{version.to_s}")
    end

    desc "Bump the gemspec by a patch version."
    task :patch => :versionomy do |t|
      version = VERSIONER.bump!(:patch)
      puts "Bumping the patch version to #{version.to_s}"
      Rake::Task['gemspec'].invoke
      Rake::Task['commit'].invoke("Bumped version to #{version.to_s}")
    end

    task :versionomy do
      require 'versionomy' unless defined?(Versionomy) # gem install versionomy
    end
  end
end

desc "Release all padrino gems"
task :publish do
  puts "Pushing to GitHub..."
  system("git push")
  puts "Pushing to Gemcutter..."
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { rake_command("gemcutter:release") }
  end
end

desc "Run tests for all padrino stack gems"
task :test do
  # Omit the padrino metagem since no tests there
  GEM_PATHS[0..-2].each do |gem_info|
    Dir.chdir(File.join(ROOT, gem_info)) { rake_command "test" }
  end
end

# Alternate testing method, load all tests and run them at once
# Keep this because this test running method exposes test flaws sometimes not found with 'test'
require 'rake/testtask'
Rake::TestTask.new(:test_alt) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'padrino-*/test/**/test_*.rb'
  test.verbose = true
end