require 'fileutils'
require 'tmpdir'

module Smoke
  # Runs every step for one combination in a fresh temp directory.
  module Runner
    STEPS = %i[generate! configure_db! bundle! migrate_empty! scaffold! db_tasks! admin! test_suite! boot!
               rerun_same! add_component!].freeze

    module_function

    def run(name, keep: ENV['SMOKE_KEEP'] == '1', project_class: Project, combinations: Combination.load)
      combination = Combination.find(name, combinations)
      root = Dir.mktmpdir("smoke-#{name}-")
      project = project_class.new(combination, root: root)
      puts "project: #{project.path}"
      begin
        STEPS.each do |step|
          puts "== #{step}"
          project.public_send(step)
        end
      rescue StepFailed => e
        raise unless combination.allowed_failure

        puts "::warning::#{name} failed, allowed by #{combination.allowed_failure}: #{e.message.lines.first}"
        return false
      ensure
        keep ? puts("kept #{root}") : FileUtils.rm_rf(root)
      end
      puts "::warning::#{name} passes; remove allowed_failure #{combination.allowed_failure}" if combination.allowed_failure
      true
    end
  end
end
