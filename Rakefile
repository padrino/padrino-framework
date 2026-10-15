# On master, or on a maintenance branch such as 0.16-stable: rake bump[X.Y.Z], then rake publish

require 'English'
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
  raise "#{args.version} is not a version like 1.2.3 or 1.2.3.rc1" unless args.version =~ /\A\d+\.\d+\.\d+(\.[a-z0-9]+)?\z/
  branch = release_branch
  series = branch[/\A(\d+\.\d+)-stable\z/, 1]
  raise "#{branch} releases #{series}.x versions, not #{args.version}" if series && !args.version.start_with?("#{series}.")
  # A submodule left at another branch's commit shows up here too.
  raise 'Commit or stash local changes, and run git submodule update --init, before bumping' unless system('git diff --quiet && git diff --cached --quiet')
  say "Updating Padrino to version #{args.version}"
  version_paths = %w[padrino-core/lib/padrino-core/version.rb padrino-performance/lib/padrino-performance/version.rb]
  version_paths.each do |path|
    version_path = File.join(__dir__, path)
    version_text = File.read(version_path).sub(/VERSION = '[a-z0-9.]+'/, "VERSION = '#{args.version}'")
    File.open(version_path, 'w') { |f| f.write version_text }
  end
  sh(format('git commit -m "Bumped version to %s" -- %s', args.version, version_paths.join(' ')))
end

desc 'Executes a fresh install removing all padrino version and then reinstall all gems'
task fresh: %i[uninstall install clean]

desc 'Pulls latest commits and updates submodules'
task :pull do
  say 'Pulling latest commits'
  branch = release_branch
  sh "git pull --ff-only origin #{branch}"
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
  remote_tag = `git ls-remote --tags origin refs/tags/#{Padrino.version}`
  raise 'Could not list the tags on origin' unless $CHILD_STATUS.success?
  if remote_tag.empty?
    say 'Pushing to github...'
    sh "git tag #{Padrino.version}"
    sh "git push origin #{branch}"
    sh "git push origin #{Padrino.version}"
  else
    # A publish that failed after tagging (say, rubygems rejected the API key) resumes from here.
    tagged = remote_tag.split.first
    local = `git rev-parse -q --verify refs/tags/#{Padrino.version}`.strip
    raise "Tag #{Padrino.version} on origin (#{tagged[0, 8]}) differs from the local tag (#{local[0, 8]})" unless local.empty? || local == tagged
    # The gems are built from the working tree, so it must be the tagged commit, and Bundler needs the tag locally.
    sh "git fetch origin refs/tags/#{Padrino.version}:refs/tags/#{Padrino.version}" if local.empty?
    head = `git rev-parse HEAD`.strip
    tagged_commit = `git rev-parse -q --verify refs/tags/#{Padrino.version}^{commit}`.strip
    unless tagged_commit == head
      raise "Tag #{Padrino.version} (#{tagged_commit[0, 8]}) is not HEAD (#{head[0, 8]}) of #{branch}; " \
            'release the missing gems from a checkout of the tag'
    end
    say "Tag #{Padrino.version} is already on origin; resuming the release"
    sh "git push origin #{branch}"
  end
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
