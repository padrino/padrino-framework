require 'fileutils'
require 'open-uri'

module Padrino
  module Generators
    ##
    # Responsible for executing plugin and template instructions including
    # common actions for modifying a project or application.
    #
    module Runner
      # Generates project scaffold based on a given template file. A project generated with --dev
      # passes it on, unless the template sets :dev itself.
      #
      # @param [Hash] options
      #   Options to use to generate the project.
      #
      # @example
      #   project test: :shoulda, orm: :activerecord, renderer: "haml"
      #
      def project(options = {})
        options = { dev: true }.merge(options) if self.options[:dev]
        components = options.sort_by { |k, _v| k.to_s }.map { |component, value| "--#{component}=#{value}" }
        params = [name, *components].push("-r=#{destination_root('../')}")
        say "=> Executing: padrino-gen project #{params.join(' ')}", :magenta
        Padrino.bin_gen(*params.unshift('project'))
      end

      ##
      # Executes generator command for specified type with given arguments.
      #
      # @param [Symbol] type
      #   Type of component module.
      # @param [String] arguments
      #   Arguments to send to component generator.
      #
      # @example
      #   generate :model, "post title:string body:text"
      #   generate :controller, "posts get:index get:new post:new"
      #   generate :migration, "AddEmailToUser email:string"
      #
      def generate(type, arguments = '')
        params = arguments.split(' ').push("-r=#{destination_root}")
        params.push("--app=#{@_app_name}") if @_app_name
        say "=> Executing: padrino-gen #{type} #{params.join(' ')}", :magenta
        in_project_bundle { Padrino.bin_gen(*params.unshift(type)) }
      end

      ##
      # Executes rake command with given arguments.
      #
      # @param [String] command
      #   Rake tasks to execute.
      #
      # @example
      #   rake "custom task1 task2"
      #
      def rake(command)
        in_project_bundle { Padrino.bin('rake', command, "-c=#{destination_root}") }
      end

      ##
      # Executes App generator. Accepts an optional block allowing generation inside subapp.
      #
      # @param [Symbol] name
      #   Name of (sub)application to generate.
      # @param [Proc] block
      #   Commands to execute in context of (sub)appliation directory.
      #
      # @example
      #   app :name
      #   app :name do
      #    generate :model, "posts title:string" # generate a model inside of subapp
      #   end
      #
      def app(name)
        say "=> Executing: padrino-gen app #{name} -r=#{destination_root}", :magenta
        created = in_project_bundle { Padrino.bin_gen(:app, name.to_s, "-r=#{destination_root}") }
        return created unless block_given?

        @_app_name = name
        yield
      ensure
        @_app_name = nil
      end

      ##
      # Executes git commmands in project.
      #
      # @param [Symbol] action
      #   Git command to execute.
      # @param [String] arguments
      #   Arguments to invoke on git command.
      #
      # @example
      #   git :init
      #   git :add, "."
      #   git :commit, "hello world"
      #
      def git(*args)
        FileUtils.cd(destination_root) do
          cmd = format('git %s', args.join(' '))
          say cmd, :green
          system cmd
        end
      end

      private

      ##
      # Runs a step that loads the project (rake, or a generator, which loads config/boot.rb) under the
      # project's bundle, as `bundle exec` in the project would. It would otherwise inherit the bundle this
      # process runs under, such as a checkout's for `bundle exec padrino-gen project -p ...`. Until the
      # project is bundled (no Gemfile.lock), the step keeps this process's bundle, which is the one that
      # can load padrino-gen from a checkout.
      #
      def in_project_bundle(&block)
        return yield unless defined?(Bundler) && File.exist?(destination_root('Gemfile.lock'))

        with_project_bundle_env(setup: true, &block)
      end

      ##
      # Resolves the path to the plugin template
      # given the project_name and the template_file.
      #
      # @param [Symbol] kind
      #   Context of template file to run, i.e :plugin, :template.
      # @param [String] template_file
      #   Path to template file.
      #
      # @example
      #   execute_runner(:plugin, 'path/to/local/file')
      #   execute_runner(:plugin, 'hoptoad')
      #   execute_runner(:template, 'sampleblog')
      #   execute_runner(:template, 'https://gist.github.com/357045')
      #
      def execute_runner(kind, template_file)
        # Determine resolved template path
        template_file = template_file.to_s
        page = template_file.sub(/[?#].*\z/m, '').chomp('/')
        template_path =
          if page =~ %r{\Ahttps?://gist\.github\.com/} && page !~ %r{/raw(/|\z)}
            # gist page: GitHub redirects <user>/<id>/raw to the gist's raw file
            "#{gist_page_with_user(page)}/raw"
          elsif template_file =~ %r{\Ahttps?://}
            template_file
          elsif File.extname(template_file).empty? # referencing official plugin (i.e hoptoad)
            "https://raw.githubusercontent.com/padrino/padrino-recipes/master/#{kind.to_s.pluralize}/#{template_file}_#{kind}.rb"
          else # local file on system
            File.expand_path(template_file)
          end

        begin
          self.apply(template_path)
        rescue StandardError => e
          say("The template at #{template_path} could not be loaded: #{e.message}", :red)
          exit 1
        end
      end

      ##
      # A gist page URL without the user (gist.github.com/<id>) redirects to the user's page.
      # Follow it, so /raw is asked for on the path GitHub serves the raw file from.
      def gist_page_with_user(page)
        return page unless page =~ %r{\Ahttps?://gist\.github\.com/[^/]+\z}
        URI.parse(page).open(&:base_uri).to_s.sub(/[?#].*\z/m, '').chomp('/')
      rescue StandardError
        page
      end
    end
  end
end
