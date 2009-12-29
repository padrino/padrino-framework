require File.dirname(__FILE__) + '/helper'

class TestAccessControl < Test::Unit::TestCase
  
  class AccessDemo < Padrino::AccessControl::Base

    roles_for :any do |role|
      role.allow "/sessions"
      role.deny  "/special"
    end

    roles_for :admin do |role, account|
      role.allow "/admin/base"
      role.deny  "/admin/accounts/details"
      role.deny  "/admin/accounts/details" # Only for check that we don't have two paths equal

      role.project_module "Padrino's Dashboard" do |project|
        project.menu :general_settings, "/admin/settings" do |submenu|
          submenu.add :accounts, "/admin/accounts" do |submenu|
            submenu.add :sub_accounts, "/admin/accounts/subaccounts"
            submenu.add :sub_accounts, "/admin/accounts/subaccounts" # Only for check that we don't have two paths equal
          end
        end
      end
    end

    roles_for :editor, :admin do |role, account|
      role.project_module :categories do |project|
        account.categories.each do |category|
          project.menu category.name, "/admin/categories/#{category.id}.js"
        end
      end
    end
  end

  def setup
    @admin       = Account.admin
    @editor      = Account.editor
    @admin_maps  = AccessDemo.auths(@admin)
    @editor_maps = AccessDemo.auths(@editor)
  end

  context 'for authorization functionality' do

    should 'check auths without account' do
      assert_equal ["/sessions"], AccessDemo.auths.allowed
      assert_equal ["/special"],  AccessDemo.auths.denied
    end

    should 'check auths for an editor' do
      assert_equal ["/special"], AccessDemo.auths(Account.editor).denied
      assert_equal ["/sessions"] + 
                   @editor.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq, 
                   AccessDemo.auths(Account.editor).allowed
    end

    should 'allow and deny paths for admin' do
      allowed = ["/sessions", "/admin/base", "/admin/settings", "/admin/accounts", "/admin/accounts/subaccounts"] +
                @admin.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq
      assert_equal ["/special", "/admin/accounts/details"], @admin_maps.denied
      assert_equal allowed, @admin_maps.allowed
    end

    should 'allow and deny paths for editor' do
      assert_equal ["/special"], @editor_maps.denied
      assert_equal ["/sessions"] + @editor.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq, @editor_maps.allowed
    end
  end

  context 'for project modules functionality do' do

    should 'check modules uids' do
      assert_equal [:padrinosdashboard, :categories], @admin_maps.project_modules.collect(&:uid)
      assert_equal [:categories], @editor_maps.project_modules.collect(&:uid)
    end

    should 'check a module config' do
      menu = @editor.categories.collect { |c| { :text => c.name, :handler => "function(){ Admin.app.load('/admin/categories/#{c.id}.js') }" } }
      assert_equal [{ :text => "Categories", :menu => menu }], @editor_maps.project_modules.collect(&:config)
    end

    should 'check config handlers' do
      assert_kind_of Padrino::ExtJs::Variable, @editor_maps.project_modules.collect(&:config).first[:menu].first[:handler]
    end
  end
end