require 'helper'

class TestAccessControl < Test::Unit::TestCase

  def setup
    load_fixture 'data_mapper'
    @access = Class.new(Padrino::AccessControl::Base)

    @access.roles_for :any do |role|
      role.allow "/sessions"
      role.deny  "/special"
    end

    @access.roles_for :admin do |role, account|
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

    @access.roles_for :editor, :admin do |role, account|
      role.project_module :categories do |project|
        account.categories.each do |category|
          project.menu category.name, "/admin/categories/#{category.id}.js"
        end
      end
    end
  end

  context 'for authorization functionality' do

    should 'check empty auths' do
      empty = Class.new(Padrino::AccessControl::Base)
      assert empty.auths.can?("/foo/bar")
      assert ! empty.auths.cannot?("/foo/bar")
    end

    should 'check auths without account' do
      assert_equal ["/sessions"], @access.auths.allowed
      assert_equal ["/special"],  @access.auths.denied
    end

    should 'act as can can' do
      assert @access.auths.can?("/sessions")
      assert @access.auths.cannot?("/special")
      assert ! @access.auths.can?("/special")
    end

    should 'check auths for an editor' do
      assert_equal ["/special"], @access.auths(Account.editor).denied
      assert_equal ["/sessions"] + 
                   Account.editor.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq, 
                   @access.auths(Account.editor).allowed
    end

    should 'allow and deny paths for admin' do
      allowed = ["/sessions", "/admin/base", "/admin/settings", "/admin/accounts", "/admin/accounts/subaccounts"] +
                Account.admin.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq
      assert_equal ["/special", "/admin/accounts/details"], @access.auths(Account.admin).denied
      assert_equal allowed, @access.auths(Account.admin).allowed
    end

    should 'allow and deny paths for editor' do
      assert_equal ["/special"], @access.auths(Account.editor).denied
      assert_equal ["/sessions"] + Account.editor.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq, @access.auths(Account.editor).allowed
    end
  end

  context 'for project modules functionality do' do

    should 'have empty modules if no account given' do
      assert_equal [], @access.auths.project_modules
    end

    should 'check modules uids' do
      assert_equal [:padrinosdashboard, :categories], @access.auths(Account.admin).project_modules.collect(&:uid)
      assert_equal [:categories], @access.auths(Account.editor).project_modules.collect(&:uid)
    end

    should 'check a module config' do
      menu = Account.editor.categories.collect { |c| { :text => c.name, :handler => "function(){ Admin.app.load('/admin/categories/#{c.id}.js') }" } }
      assert_equal [{ :text => "Categories", :menu => menu }], @access.auths(Account.editor).project_modules.collect(&:config)
    end

    should 'check config handlers' do
      assert_kind_of Padrino::ExtJs::Variable, @access.auths(Account.editor).project_modules.collect(&:config).first[:menu].first[:handler]
    end
  end

end