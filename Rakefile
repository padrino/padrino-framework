require "rake/clean"
require "rake/gempackagetask"
require 'fileutils'
include FileUtils

gems = [
  "padrino-core",
  "padrino-cache",
  "padrino-admin",
  "padrino-gen",
  "padrino-helpers",
  "padrino-mailer",
  "padrino-routing",
  "padrino"
]

%w(clean install gemspec build release).each do |task_name|
  desc "Run #{task_name} for all projects"
  task task_name do
    gems.each do |dir|
      Dir.chdir(dir) { sh "#{Gem.ruby} -S rake #{task_name}" }
    end
  end
end

desc "Bump patch version and release all padrino gems"
task :publish do
  gems.each do |dir|
    Dir.chdir(dir) { sh "#{Gem.ruby} -S rake version:bump:patch release" }
  end
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'padrino-*/test/**/test_*.rb'
  test.verbose = true
end
