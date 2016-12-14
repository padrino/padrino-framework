PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class StaticDemo < Padrino::Application
    disable :reload
    def self.reload!
        raise 'reload! called'
    end
end

Padrino.load!
