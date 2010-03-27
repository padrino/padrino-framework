# Simple patch (X.X.X+) release is: rake version:bump:tiny  publish
# Simple minor (X.X+.X) release is: rake version:bump:minor publish
# Simple minor (X+.X.X) release is: rake version:bump:major publish

require 'pathname'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'
require 'fileutils'
require 'sdoc'
require File.expand_path(File.dirname(__FILE__) + '/versioner')

include FileUtils

ROOT        = Pathname(__FILE__).dirname.expand_path
GEM_NAME    = 'padrino-framework'
GEM_VERSION = ROOT.join('VERSION').read.chomp
VERSIONER   = Versioner.new(GEM_VERSION, Dir[File.dirname(__FILE__) + '/**/VERSION'])

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
      %w(doc tmp pkg coverage).each { |dir| FileUtils.rm_rf dir }
    end
  end
  Dir["**/*.gem"].each { |gem| FileUtils.rm_rf gem }
end

desc "Clean pkg and other stuff"
task :uninstall do
  sh "gem search --no-version padrino | grep padrino | xargs sudo gem uninstall -a"
end

desc "Displays the current version"
task :version do
  puts "Current version: #{VERSIONER.current_version}"
end

desc "Commits all staged files"
task :commit, [:message] do |t, args|
  system("git commit -a -m \"#{args.message}\"")
end

desc "Generate documentation for the Rails framework"
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
    task :tiny => :versionomy do |t|
      version = VERSIONER.bump!(:tiny)
      puts "Bumping the patch version to #{version.to_s}"
      Rake::Task['gemspec'].invoke
      Rake::Task['commit'].invoke("Bumped version to #{version.to_s}")
    end

    task :versionomy do
      require 'versionomy' unless defined?(Versionomy) # gem install versionomy
    end
  end
end

desc "Publish doc on padrino.github.com"
task :pdoc => :rdoc do
  puts "Publishing doc on padrinorb.com ..."
  Rake::SshDirPublisher.new("root@lipsiasoft.biz", "/mnt/www/apps/padrino/public/api", "doc").upload
  FileUtils.rm_rf "doc"
end

desc "Release all padrino gems"
task :publish do
  puts "Pushing to Gemcutter..."
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { rake_command("gemcutter:release") }
  end
  rake_command("clean")
end

desc "Run tests for all padrino stack gems"
task :default => :test

desc "Run tests for all padrino stack gems"
task :test do
  # Omit the padrino metagem since no tests there
  GEM_PATHS[0..-2].each do |gem|
    Dir.chdir(File.join(ROOT, gem)) { rake_command "test" }
  end
end

desc "Execute a fresh install removing all padrino version and then reinstall all gems"
task :fresh => [:uninstall, :install, :clean]