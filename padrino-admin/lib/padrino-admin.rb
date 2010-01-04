require 'padrino-core'
Dir[File.dirname(__FILE__) + '/padrino-admin/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/padrino-admin/{access_control,adapters,ext_js,generators,utils}/*.rb'].each {|file| require file }

Padrino::Application.send(:cattr_accessor, :access_control)
Padrino::Application.send(:access_control=, Class.new(Padrino::AccessControl::Base))
String.send(:include, Padrino::Admin::Utils::Crypt)