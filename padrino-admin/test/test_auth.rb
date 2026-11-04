require_relative 'helper'
require 'open3'
require 'rbconfig'

describe 'Padrino::Auth' do
  it 'aliases AccessControlError to Auth::Error' do
    assert_same Padrino::Auth::Error, Padrino::Admin::AccessControlError
  end

  it 'checks rules without the admin' do
    rules = Padrino::Auth::Rules.new
    rules.roles_for(:any) { |a| a.protect '/secret'; a.allow '/open' }
    refute rules.allowed?(nil, '/secret')
    assert rules.allowed?(nil, '/open')
  end

  it 'gives a subclass of AccessControl::Base project_module' do
    klass = Class.new(Padrino::Admin::AccessControl::Base)
    rules = klass.new
    rules.roles_for(:any) { |a| a.project_module :foo, '/foo' }
    assert_equal '/foo', rules.project_modules(:any).first.path
  end

  it 'loads auth.rb without padrino-admin' do
    root = File.expand_path('../..', __dir__)
    libs = %w[padrino-core padrino-support padrino-admin].map { |gem| "-I#{File.join(root, gem, 'lib')}" }
    code = "require 'padrino-core'; require 'padrino-admin/auth'; p [defined?(Padrino::Admin), defined?(Padrino::Helpers), defined?(I18n)]"
    output, status = Open3.capture2e(RbConfig.ruby, *libs, '-e', code)
    assert status.success?, output
    assert_equal "[nil, nil, nil]\n", output
  end
end
