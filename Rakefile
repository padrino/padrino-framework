# On master, or on a maintenance branch such as 0.16-stable: rake bump[X.Y.Z], then rake publish

require 'fileutils'
require 'rake'
require File.expand_path('padrino-core/lib/padrino-core/version.rb', __dir__)

load File.expand_path('padrino/subgems.rb', __dir__)
GEM_PATHS = PADRINO_GEMS.keys
ROOT = __dir__

def sh_rake(command)
  sh "#{Gem.ruby} -S rake #{command}", verbose: true
end

# Releases are cut from master, or from an X.Y-stable branch for X.Y.Z maintenance releases.
def release_branch
  branch = `git rev-parse --abbrev-ref HEAD`.strip
  return branch if branch == 'master' || branch =~ /\A\d+\.\d+-stable\z/
  raise "Release from master or an X.Y-stable branch, not #{branch}"
end

def say(text, color = :magenta)
  n = { bold: 1, red: 31, green: 32, yellow: 33, blue: 34, magenta: 35 }.fetch(color, 0)
  puts format("\e[%dm%s\e[0m", n, text)
end

desc "Run 'install' for all projects"
task :install do
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { sh_rake(:install) }
  end
end

desc 'Clean pkg and other stuff'
task :clean do
  GEM_PATHS.each do |g|
    %w[tmp pkg coverage].each { |dir| sh(format('rm -rf %s', File.join(g, dir))) }
  end
end

desc 'Clean pkg and other stuff'
task :uninstall do
  GEM_PATHS.each do |gem|
    system("gem uninstall #{gem} --force -I -x 2>/dev/null")
  end
end

desc 'Displays the current version'
task :version do
  say "Current version: #{Padrino.version}"
end

desc 'Bumps the version number based on given version'
task :bump, [:version] do |_t, args|
  raise 'Please specify version=x.x.x !' unless args.version
  branch = release_branch
  series = branch[/\A(\d+\.\d+)-stable\z/, 1]
  raise "#{branch} releases #{series}.x versions, not #{args.version}" if series && !args.version.start_with?("#{series}.")
  say "Updating Padrino to version #{args.version}"
  %w[padrino-core/lib/padrino-core/version.rb padrino-performance/lib/padrino-performance/version.rb].each do |path|
    version_path = File.join(__dir__, path)
    version_text = File.read(version_path).sub(/VERSION = '[a-z0-9.]+'/, "VERSION = '#{args.version}'")
    File.open(version_path, 'w') { |f| f.write version_text }
  end
  sh(format('git commit -am "Bumped version to %s"', args.version))
end

desc 'Executes a fresh install removing all padrino version and then reinstall all gems'
task fresh: %i[uninstall install clean]

desc 'Pulls latest commits and updates submodules'
task :pull do
  say 'Pulling latest commits'
  branch = release_branch
  sh "git pull origin #{branch}"
  say 'Updating submodules'
  sh 'git submodule sync'
  sh 'git submodule update --init'
  # A maintenance release ships the static files its branch pins.
  sh 'git submodule foreach git pull origin master' if branch == 'master'
  sh 'ls padrino-gen/lib/padrino-gen/generators/templates/static/README.rdoc'
end

desc 'Pushes repository to GitHub'
task push: :pull do
  raise 'Commit or stash local changes before releasing' unless system('git diff --quiet && git diff --cached --quiet')
  committed = File.read(File.join(__dir__, 'padrino-core/lib/padrino-core/version.rb'))[/VERSION = '([^']+)'/, 1]
  branch = release_branch
  raise "#{branch} has version #{committed}, not #{Padrino.version}; run rake bump on #{branch}" unless committed == Padrino.version
  say 'Pushing to github...'
  sh "git tag #{Padrino.version}"
  sh "git push origin #{branch}"
  sh "git push origin #{Padrino.version}"
end

desc 'Release all padrino gems'
task publish: :push do
  say 'Pushing to rubygems...'
  GEM_PATHS.each do |dir|
    Dir.chdir(dir) { sh_rake('release') }
  end
  Rake::Task['clean'].invoke
end
task release: :publish

desc 'Run tests for all padrino stack gems'
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

desc 'Generate documentation for the Padrino framework'
task :doc do
  require 'yard'
  YARD::CLI::Yardoc.new.run
end

desc 'Run tests for all padrino stack gems'
task default: :test
