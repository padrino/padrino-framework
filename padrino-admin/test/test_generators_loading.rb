require_relative 'helper'
require 'open3'

describe 'Loading padrino-admin' do
  # This process has padrino-gen loaded (helper.rb), so each check runs in a fresh Ruby.
  def run_ruby(script)
    env = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] || File.expand_path('../../Gemfile', __dir__) }
    out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script)
    assert status.success?, err
    out
  end

  it 'should not load padrino-gen or its String extensions' do
    out = run_ruby(<<~'RUBY')
      require 'padrino-admin'
      p [defined?(Padrino::Generators), ''.respond_to?(:pluralize), ''.respond_to?(:constantize)]
    RUBY
    assert_equal "[nil, false, false]\n", out
  end

  it 'should add the admin generators to padrino-gen loaded before or after it' do
    [%w[padrino-gen padrino-admin], %w[padrino-admin padrino-gen]].each do |libs|
      out = run_ruby(<<~RUBY)
        require 'thor/group'
        #{libs.map { |lib| "require '#{lib}'" }.join("\n")}
        Padrino::Generators.load_components!
        p Padrino::Generators.mappings.values_at(:admin, :admin_page).map(&:name)
      RUBY
      assert_equal %(["Padrino::Generators::AdminApp", "Padrino::Generators::AdminPage"]\n), out, libs.join(' then ')
    end
  end
end
