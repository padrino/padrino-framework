require 'padrino-core'
Dir[File.dirname(__FILE__) + '/padrino-admin/**/*.rb'].each {|file| require file }

# This module give to a padrino application an access control functionality like:
# 
#   class AdminDemo < Padrino::Application
#     roles_for :administrator do |role, current_account|
#       role.allow "/admin/base"
#       role.deny  "/admin/accounts/details"
#     
#       role.project_module :administration do |project|
#         project.menu :general_settings, "/admin/settings" do |submenu|
#           submenu.add :accounts, "/admin/accounts" do |submenu|
#             submenu.add :sub_accounts, "/admin/accounts/subaccounts"
#           end
#         end
#       end
# 
#       role.project_module :categories do |project|
#         current_account.categories.each do |cat|
#           project.menu cat.name, "/admin/categories/#{cat.id}.js"
#         end
#       end
#     end
#   end
#   
module Padrino
  class Application
    @@access_control = Class.new(Padrino::AccessControl::Base)
    cattr_reader :access_control

    set :login_from, :sessions
    helpers Padrino::AccessControl::Helpers

    # Delegator for roles
    def self.roles_for(*roles, &block)
      @@access_control.roles_for(*roles, &block)
    end
  end
end
