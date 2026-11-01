module Padrino
  module Generators
    module Admin
      ##
      # Keeps an existing file when its overwrite prompt is left unanswered.
      #
      module KeepFiles
        ##
        # Answers no at the end of input (no terminal, empty pipe), which Thor takes as a yes.
        # Other answers, including piped ones, work as usual.
        #
        module Shell
          def file_collision(destination)
            @resolving_file_collision = true
            super
          ensure
            @resolving_file_collision = false
          end

          def ask(statement, *args)
            answer = super
            answer.nil? && @resolving_file_collision ? 'n' : answer
          end
        end

        def shell
          super.extend(Shell)
        end

        ##
        # Tells whether the file exists and has a line matching the pattern.
        #
        def line_in_file?(path, pattern)
          File.exist?(path) && File.binread(path).match?(pattern)
        end

        ##
        # Adds the access_control permission unless the app has one for the controller, edited or not.
        #
        def add_missing_project_module(controller)
          add_project_module(controller) unless line_in_file?(destination_root("#{@admin_path}/app.rb"), /^\s*role\.project_module[\s(]+:#{controller}\b/)
        end

        ##
        # Stops when the admin can't log in with an existing model and nobody is left to answer whether to replace it.
        #
        def stop_for_model_without_login(path)
          return if !File.exist?(path) || line_in_file?(path, /\bauthenticate\b/) || $stdin.tty? || !$stdin.eof?

          raise Thor::Error, "#{path} has no authenticate method and no input is left to confirm replacing it. " \
                             'Add the method to the model, or run the generator in a terminal to choose whether to replace the file.'
        end
      end
    end
  end
end
