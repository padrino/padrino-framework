require File.expand_path('../../tasks', __FILE__)
require 'rake'
require 'rake/dsl_definition'
require 'thor'
require 'securerandom' unless defined?(SecureRandom)
begin
  require 'padrino-gen'
rescue LoadError
end

module PadrinoTasks
  def self.init(init=false)
    lib_path = File.expand_path("lib")
    unless $LOAD_PATH.any?{ |path| File.expand_path(path) == lib_path }
      warn <<-EOT
WARNING! In Padrino >= 0.14.0 cli command `padrino rake` will NOT add
'./lib' folder to $LOAD_PATH. Please alter your `require` calls accordingly
if you depend on this behavior.
      EOT
      $LOAD_PATH.unshift lib_path
    end
    Padrino::Tasks.files.flatten.uniq.each { |rakefile| Rake.application.add_import(rakefile) rescue puts "<= Failed load #{ext}" }
    load(File.expand_path('../rake_tasks.rb', __FILE__))
    Rake.application.load_imports
  end

  def self.use(task)
    tasks << task
  end

  def self.tasks
    @tasks ||= []
  end

  def self.load?(task, constant_present)
    if constant_present && !PadrinoTasks.tasks.include?(task)
      warn <<-WARNING
Loading #{task} tasks automatically.
This functionality will be disabled in future versions. Please put

  PadrinoTasks.use(#{task.inspect})
  PadrinoTasks.init

and remove

  require File.expand_path('../config/boot.rb', __FILE__)

in you Rakefile instead.
      WARNING
    end

    constant_present || PadrinoTasks.tasks.include?(task)
  end
end

def shell
  @_shell ||= Thor::Base.shell.new
end
