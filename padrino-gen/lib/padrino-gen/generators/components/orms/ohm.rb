OHM = (<<-OHM) unless defined?(OHM)
# Ohm does not have the concept of namespaces
# This means that you will not be able to have
# a distinct test,development or production database
#
# You can, however, run multiple redis servers on the same host
# and point to them based on the environment:
#
# case Padrino.env
#  when :development then Ohm.connect(:port => 6379)
#  when :production then Ohm.connect(:port => 6380)
#  when :test then Ohm.connect(:port => 6381)
# end

# Alternatively, you can try specifying a difference :db
# which, outside of confirmation, appears to provide distinct
# namespaces from testing
# case Padrino.env
#  when :development then Ohm.connect(:db => 0)
#  when :production then Ohm.connect(:db => 1)
#  when :test then Ohm.connect(:db => 2)
# end

# this monkey patch provides traditional (hash of arrays) error handling for ohm models
unless Ohm::Model.new.errors.kind_of? Hash
  module Ohm
    class Model

      alias_method :old_errors, :errors

      def errors
        @errors ||= ErrorsHash.new(self.class.to_reference, self.old_errors)
      end

      class ErrorsHash < Hash
        def initialize(scope, errors)
          @scope  = scope
          self.replace Hash.new { |hash, key| hash[key] = [] }

          errors.each do |key, value|
            self[key] << value
          end
        end

        def push(arr)
          self[arr[0]] << arr[1]
        end

        def full_messages
          self.map do |key, value|
            value.uniq.map do |reason|
              I18n::t("ohm.%s.%s.%s" % [@scope, key, reason])
            end.join(', ')
          end
        end
      end

      def update_attributes(attrs)
        attrs.each do |key, value|
          send(:"\#{key}=", value)
        end  if attrs
      end

    end
  end
end
OHM

def setup_orm
  ohm = OHM
  require_dependencies 'json'
  require_dependencies 'ohm', :require => 'ohm'
  require_dependencies 'ohm-contrib', :require => 'ohm/contrib'
  create_file("config/database.rb", ohm)
end

OHM_MODEL = (<<-MODEL) unless defined?(OHM_MODEL)
class !NAME! < Ohm::Model
  include Ohm::Timestamping
  include Ohm::Typecast

  # Examples:
  # attribute :name
  # attribute :email, String
  # reference :venue, Venue
  # set :participants, Person
  # counter :votes
  #
  # index :name
  #
  # def validate
  #   assert_present :name
  # end

  !FIELDS!
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
    model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
    field_tuples = options[:fields].map { |value| value.split(":") }
    column_declarations = field_tuples.map { |field, kind| "attribute :#{field}, #{kind.underscore.camelize}" }.join("\n  ")
    model_contents = OHM_MODEL.gsub(/!NAME!/, name.to_s.underscore.camelize)
    model_contents.gsub!(/!FIELDS!/, column_declarations)
    create_file(model_path, model_contents)
end

def create_model_migration(filename, name, fields)
  # NO MIGRATION NEEDED
end

def create_migration_file(migration_name, name, columns)
  # NO MIGRATION NEEDED
end
