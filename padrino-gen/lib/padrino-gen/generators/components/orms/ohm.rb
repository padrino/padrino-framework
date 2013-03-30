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
OHM

OHM_VALIDATIONS = (<<-VALIDATIONS) unless defined?(OHM_VALIDATIONS)
# Provides traditional (hash of arrays) error handling for ohm models
# Also adds compatiblity with admin generator.
module Padrino
  module Ohm
    module Validations
      include Scrivener::Validations

      def errors
        @errors ||= ErrorHash.new(self.class.to_reference, super)
      end

      # override default errors and provide ActiveModel equivenents
      def assert_format(att, format, error = [att, :invalid])
        super
      end

      def assert_present(att, error = [att, :blank])
        super
      end

      def assert_numeric(att, error = [att, :not_a_number])
        super
      end

      def assert_url(att, error = [att, :invalid])
        super
      end

      def assert_email(att, error = [att, :invalid])
        super
      end

      def assert_member(att, set, err = [att, :inclusion])
        super
      end

      def assert_length(att, range, error = [att, :wrong_length])
        super
      end

      def assert_decimal(att, error = [att, :invalid]) 
        super
      end

      class ErrorHash < Hash
        def initialize(scope, errors)
          @scope = scope

          self.default_proc = proc do |hash, key|
            hash[key] = []
          end
        end

        def push(arr)
          self[arr.first] << arr.last
        end

        def full_messages
          self.map do |key, value|
            value.uniq.map do |reason|
              I18n::t("ohm.%s.%s.%s" % [@scope, key, reason])
            end.join(', ')
          end
        end
      end

    end
  end
end
VALIDATIONS

def setup_orm
  require_dependencies 'ohm', :version => "~> 1.3.0"
  create_file("config/database.rb", OHM)
  create_file("lib/padrino_ohm_validations.rb", OHM_VALIDATIONS)
end

OHM_MODEL = (<<-MODEL) unless defined?(OHM_MODEL)
class !NAME! < Ohm::Model
  # Examples:
  # attribute :name
  # attribute :email
  # reference :venue, Venue
  # set :participants, Person
  # counter :votes
  #
  # index :name
  #
  # def validate
  #   assert_present :name
  # end

  include Padrino::Ohm::Validations

  !FIELDS!
end
MODEL

# options => { :fields => ["title:string", "body:string"], :app => 'app' }
def create_model_file(name, options={})
    model_path = destination_root(options[:app], 'models', "#{name.to_s.underscore}.rb")
    field_tuples = options[:fields].map { |value| value.split(":") }
    column_declarations = field_tuples.map { |field, kind| "attribute :#{field}" }.join("\n  ")
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
