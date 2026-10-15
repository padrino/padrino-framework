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

def setup_script
  # Start on a new line so a file without a trailing newline keeps its last line intact.
  append_line = lambda do |path, text|
    content = File.read(path)
    append_file path, content.empty? || content.end_with?("\n") ? text : "\n#{text}"
  end

  gemfile = destination_root('Gemfile')
  require_dependencies 'activesupport', version: '>= 3.1' unless File.exist?(gemfile) && File.read(gemfile).match?(/^\s*gem[\s(]+['"]activesupport['"]/)
  require_dependencies 'vite_padrino', version: '~> 3.0'
  boot = destination_root('config/boot.rb')
  try_require = "require 'active_support/core_ext/object/try' # vite_padrino 3.0.0 needs it until https://github.com/ElMassimo/vite_ruby/pull/635 ships\n"
  inject_into_file boot, try_require, after: "Bundler.require(:default, RACK_ENV)\n"
  unless File.read(boot).include?('active_support/core_ext/object/try')
    say "Add `require 'active_support/core_ext/object/try'` after Bundler.require in config/boot.rb: vite_padrino 3.0.0 needs Object#try.", :red
  end
  initializer :VitePadrino
  create_file destination_root('config/vite.json'), VITE_JSON, skip: true
  create_file destination_root('vite.config.ts'), VITE_CONFIG, skip: true
  package_json_exists = File.exist?(destination_root('package.json'))
  create_file destination_root('package.json'), VITE_PACKAGE_JSON, skip: true
  create_file destination_root('app/frontend/entrypoints/application.js'), VITE_ENTRYPOINT, skip: true
  procfile = destination_root('Procfile.dev')
  if File.exist?(procfile)
    append_line.call(procfile, "vite: bundle exec vite dev\n") unless File.read(procfile).match?(/^vite:/)
  else
    create_file procfile, "web: bundle exec padrino start\nvite: bundle exec vite dev\n"
  end
  append_file destination_root('Rakefile'), VITE_RAKE if File.exist?(destination_root('Rakefile'))
  append_line.call(destination_root('.gitignore'), VITE_GITIGNORE) if File.exist?(destination_root('.gitignore'))
  renderer = fetch_component_choice(:renderer).to_s
  renderer = 'erb' unless %w[haml slim].include?(renderer)
  tags = renderer == 'erb' ? ['<%= vite_client_tag %>', "<%= vite_javascript_tag 'application' %>"] : ['= vite_client_tag', "= vite_javascript_tag 'application'"]
  install = package_json_exists ? 'npm install -D vite@^8.0.0 vite-plugin-ruby@^5.2.5' : 'npm install'
  say "Run `#{install}` to install Vite, then add to the <head> of your layout (app/views/layouts/application.#{renderer}):", :yellow
  say tags.map { |tag| "  #{tag}" }.join("\n"), :yellow
end
