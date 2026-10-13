VITE_JSON = <<~JSON unless defined?(VITE_JSON)
  {
    "development": {
      "autoBuild": true,
      "publicOutputDir": "vite-dev"
    },
    "test": {
      "autoBuild": true,
      "publicOutputDir": "vite-test"
    }
  }
JSON

VITE_CONFIG = <<~TS unless defined?(VITE_CONFIG)
  import { defineConfig } from 'vite'
  import RubyPlugin from 'vite-plugin-ruby'

  export default defineConfig({
    plugins: [
      RubyPlugin(),
    ],
  })
TS

VITE_PACKAGE_JSON = <<~JSON unless defined?(VITE_PACKAGE_JSON)
  {
    "private": true,
    "type": "module",
    "devDependencies": {
      "vite": "^8.0.0",
      "vite-plugin-ruby": "^5.2.5"
    }
  }
JSON

VITE_ENTRYPOINT = <<~JS unless defined?(VITE_ENTRYPOINT)
  // Vite entrypoint, load it in your layout with `vite_javascript_tag 'application'`.
  // Import other scripts and stylesheets from app/frontend here, e.g.:
  // import '~/stylesheets/application.css'
  console.log('Vite ⚡️ Padrino')
JS

VITE_RAKE = <<~RUBY unless defined?(VITE_RAKE)

  require 'vite_padrino'
  ViteRuby.install_tasks
RUBY

VITE_GITIGNORE = <<~GITIGNORE unless defined?(VITE_GITIGNORE)
  /public/vite*
  node_modules
  *.local
GITIGNORE

VITE_GEMS = <<~RUBY unless defined?(VITE_GEMS)
  gem 'vite_padrino', '~> 3.0'
  # vite_padrino 3.0.0 calls ActiveSupport's `try`, the fix in https://github.com/ElMassimo/vite_ruby/pull/635 is pending
  gem 'activesupport', '>= 3.1', require: 'active_support/core_ext/object/try'
RUBY

def setup_script
  inject_into_file 'Gemfile', VITE_GEMS, after: "Component requirements\n"
  initializer :VitePadrino
  create_file destination_root('config/vite.json'), VITE_JSON
  create_file destination_root('vite.config.ts'), VITE_CONFIG
  package_json_exists = File.exist?(destination_root('package.json'))
  create_file destination_root('package.json'), VITE_PACKAGE_JSON, skip: true
  create_file destination_root('app/frontend/entrypoints/application.js'), VITE_ENTRYPOINT
  create_file destination_root('Procfile.dev'), "web: bundle exec padrino start\nvite: bundle exec vite dev\n", skip: true
  append_file destination_root('Rakefile'), VITE_RAKE
  append_file destination_root('.gitignore'), VITE_GITIGNORE if File.exist?(destination_root('.gitignore'))
  renderer = fetch_component_choice(:renderer).to_s
  renderer = 'erb' unless %w[haml slim].include?(renderer)
  tags = renderer == 'erb' ? ['<%= vite_client_tag %>', "<%= vite_javascript_tag 'application' %>"] : ['= vite_client_tag', "= vite_javascript_tag 'application'"]
  install = package_json_exists ? 'npm install -D vite@^8.0.0 vite-plugin-ruby@^5.2.5' : 'npm install'
  say "Run `#{install}` to install Vite, then add to the <head> of your layout (app/views/layouts/application.#{renderer}):", :yellow
  say tags.map { |tag| "  #{tag}" }.join("\n"), :yellow
end
