##
# Loads our locale configuration files
#
unless defined?(PADRINO_I18N_LOCALE)
  PADRINO_I18N_LOCALE = true
  I18n.load_path += Dir["#{__dir__}/locale/*.yml"]
end
