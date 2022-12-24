# rake bump[X.X.X] && rake publish
require 'fileutils'
require 'rake'
require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

load File.expand_path('../padrino/subgems.rb', __FILE__)
GEM_PATHS = PADRINO_GEMS.keys
ROOT = File.expand_path(File.dirname(__FILE__))

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
  GEM_PATHS.each {|gem|
    system("gem uninstall #{gem} --force -I -x 2>/dev/null")
  }
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

desc "Pulls latest commits and updates submodules"
task :pull do
  say "Pulling latest commits"
  sh "git checkout master"
  sh "git pull origin master"
  say "Updating submodules"
  sh "git submodule update"
  sh "git submodule foreach git pull origin master"
  sh "ls padrino-gen/lib/padrino-gen/generators/templates/static/README.rdoc"
end

desc "Pushes repository to GitHub"
task :push => :pull do
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
  GEM_PATHS.each do |g|
    # Hardcode the 'cd' into the command and do not use Dir.chdir because this causes random tests to fail
    sh "cd #{File.join(ROOT, g)} && #{Gem.ruby} -S rake test"
  end
end

GEM_PATHS.each do |element|
  desc "Run tests for #{element} component"
  task element.to_s do
    sh "cd #{element} && #{Gem.ruby} -S rake test"
  end
end

desc "Generate documentation for the Padrino framework"
task :doc do
  require 'yard'
  YARD::CLI::Yardoc.new.run
end

desc "Run tests for all padrino stack gems"
task :default => :test
