require File.dirname(__FILE__) + '/helper'

class TestAccessControl < Test::Unit::TestCase
  
  class AccessDemo < Padrino::AccessControl::Base

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
    @admin_maps  = AccessDemo.maps_for(AdminAccount)
    @editor_maps = AccessDemo.maps_for(EditorAccount)
  end

  context 'for authorization functionality' do

    should 'allow and deny paths for admin' do
      allowed = ["/admin/base", "/admin/settings", "/admin/accounts", "/admin/accounts/subaccounts"] +
                AdminAccount.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq
      assert_equal ["/admin/accounts/details"], @admin_maps.denied
      assert_equal allowed, @admin_maps.allowed
    end

    should 'allow and deny paths for editor' do
      assert_equal [], @editor_maps.denied
      assert_equal EditorAccount.categories.collect { |c| "/admin/categories/#{c.id}.js" }.uniq, @editor_maps.allowed
    end
  end

  context 'for project modules functionality do' do

    should 'check modules uids' do
      assert_equal [:padrinosdashboard, :categories], @admin_maps.project_modules.collect(&:uid)
      assert_equal [:categories], @editor_maps.project_modules.collect(&:uid)
    end

    should 'check a module config' do
      menu = EditorAccount.categories.collect { |c| { :text => c.name, :handler => "function(){ Admin.app.load('/admin/categories/#{c.id}.js') }" } }
      assert_equal [{ :text => "Categories", :menu => menu }], @editor_maps.project_modules.collect(&:config)
    end

    should 'check config handlers' do
      assert_kind_of Padrino::ExtJs::Variable, @editor_maps.project_modules.collect(&:config).first[:menu].first[:handler]
    end
  end
end