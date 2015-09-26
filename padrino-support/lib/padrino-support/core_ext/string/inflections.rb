require 'active_support/inflections'                        # load default inflections
require 'active_support/inflector/methods'                  # constantize
require 'active_support/inflector/inflections'              # pluralize

##
# This is an adapted version of active_support/core_ext/string/inflections.rb
# to prevent loading several dependencies including I18n gem.
#
# Issue: https://github.com/rails/rails/issues/1526
#
class String
  ##
  # Returns the plural form of the word in the string.
  #
  #   "post".pluralize             # => "posts"
  #   "octopus".pluralize          # => "octopi"
  #   "sheep".pluralize            # => "sheep"
  #   "words".pluralize            # => "words"
  #   "the blue mailman".pluralize # => "the blue mailmen"
  #   "CamelOctopus".pluralize     # => "CamelOctopi"
  #
  def pluralize
    ActiveSupport::Inflector.pluralize(self)
  end

  ##
  # Returns the singular form of the word in the string.
  #
  #   "posts".singularize            # => "post"
  #   "octopi".singularize           # => "octopus"
  #   "sheep".singularize            # => "sheep"
  #   "words".singularize            # => "word"
  #   "the blue mailmen".singularize # => "the blue mailman"
  #   "CamelOctopi".singularize      # => "CamelOctopus"
  #
  def singularize
    ActiveSupport::Inflector.singularize(self)
  end

  ##
  # +constantize+ tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #
  #   "Module".constantize # => Module
  #   "Class".constantize  # => Class
  #
  def constantize
    ActiveSupport::Inflector.constantize(self)
  end

  ##
  # The reverse of +camelize+. Makes an underscored, lowercase form from the expression in the string.
  #
  # +underscore+ will also change '::' to '/' to convert namespaces to paths.
  #
  #   "ActiveRecord".underscore         # => "active_record"
  #   "ActiveRecord::Errors".underscore # => active_record/errors
  #
  def underscore
    ActiveSupport::Inflector.underscore(self)
  end

  ##
  # By default, +camelize+ converts strings to UpperCamelCase. If the argument to camelize
  # is set to <tt>:lower</tt> then camelize produces lowerCamelCase.
  #
  # +camelize+ will also convert '/' to '::' which is useful for converting paths to namespaces.
  #
  #   "active_record".camelize                # => "ActiveRecord"
  #   "active_record".camelize(:lower)        # => "activeRecord"
  #   "active_record/errors".camelize         # => "ActiveRecord::Errors"
  #   "active_record/errors".camelize(:lower) # => "activeRecord::Errors"
  #
  def camelize(first_letter = :upper)
    case first_letter
      when :upper then ActiveSupport::Inflector.camelize(self, true)
      when :lower then ActiveSupport::Inflector.camelize(self, false)
    end
  end
  alias_method :camelcase, :camelize

  ##
  # Create a class name from a plural table name like Rails does for table names to models.
  # Note that this returns a string and not a class. (To convert to an actual class
  # follow +classify+ with +constantize+.)
  #
  #   "egg_and_hams".classify # => "EggAndHam"
  #   "posts".classify        # => "Post"
  #
  # Singular names are not handled correctly.
  #
  #   "business".classify # => "Busines"
  #
  def classify
    ActiveSupport::Inflector.classify(self)
  end
end
