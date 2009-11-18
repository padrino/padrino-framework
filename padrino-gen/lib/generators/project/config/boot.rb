# This file is merely for beginning the boot process
PADRINO_ROOT = File.dirname(__FILE__) + '/..' unless defined? PADRINO_ROOT

# Loads the required files into the application
require 'padrino'
Padrino.load!