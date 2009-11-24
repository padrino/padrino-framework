require 'pathname'
require "rake/clean"
require "rake/gempackagetask"
require 'fileutils'
include FileUtils

ROOT = Pathname(__FILE__).dirname.expand_path
GEM_NAME = 'padrino-framework'
GEM_VERSION = ROOT.join('VERSION').read

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
  padrino_gems.each do |dir|
    Dir.chdir(dir) do
      FileUtils.rm_rf "doc"
      FileUtils.rm_rf "tmp"
      FileUtils.rm_rf "pkg"
    end
  end
end

desc "Clean pkg and other stuff"
task :uninstall do
  padrino_gems.each do |gem|
    sh "gem uninstall #{gem} -a"
  end
end

desc "Release all padrino gems"
task :publish do
  padrino_gems.each do |dir|
    Dir.chdir(dir) { rake_command("gemcutter:release") }
  end
end

# NOTE: this task must be named release_all, and not release
desc "Release #{GEM_NAME} #{GEM_VERSION}"
task :release_all do
  # sh "rake release VERSION=#{GEM_VERSION}"
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { rake_command "release VERSION=#{GEM_VERSION}" }
  end
end

desc "Run tests for all padrino stack gems"
task :test do
  # Omit the padrino metagem since no tests there
  padrino_gems[0..-2].each do |gem_info|
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
