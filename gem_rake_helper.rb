require 'rubygems/specification'
require 'rake'
require 'rubygems/package_task'

# Runs the sh command with sudo if the rake command is run with sudo
def sudo_sh(command)
  command = `whoami`.strip! != "root" ? "sudo #{command}" : command
  sh command
end

# Returns the gem specification object for a gem
def gemspec
  @gemspec ||= begin
    gem_name =  File.basename(File.dirname(RAKE_ROOT))
    file = File.expand_path("../#{gem_name}.gemspec", RAKE_ROOT)
    ::Gem::Specification.load(file)
  end
end

# These are the uniform tasks used to build the individual padrino gems
#
# Use these by requiring them into the Rakefile in a gem
#   RAKE_ROOT = __FILE__
#   require 'rubygems'
#   require File.expand_path(File.dirname(__FILE__) + '/../gem_rake_helper')
#
# Most notable functions are:
#   $ rake test    # runs all tests
#   $ rake package # packages the gem into the pkg folder
#   $ rake install # installs the gem into system
#   $ rake release # publishes gem to rubygems

desc "Validates the gemspec"
task :gemspec do
  gemspec.validate
end

desc "Displays the current version"
task :version do
  puts "Current version: #{gemspec.version}"
end

desc "Installs the gem locally"
task :install => :package do
  sh "gem install pkg/#{gemspec.name}-#{gemspec.version}"
end

desc "Release the gem"
task :release => :package do
  sh "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem"
end

# rake test
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/test_*.rb']
  test.verbose = true
end

# rake package
Gem::PackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
end
task :gem => :gemspec
task :package => :gemspec

task :default => :test