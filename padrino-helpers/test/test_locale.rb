require File.expand_path("#{File.dirname(__FILE__)}/helper")

describe 'Locale Helpers' do
  Dir[File.expand_path('../lib/padrino-helpers/locale/*.yml', __dir__)].each do |file|
    base_original = YAML.load_file(file)
    name = File.basename(file, '.yml')

    it "should should have correct locale for #{name}" do
      base = base_original[name]['number']['format']
      refute_nil base['separator']
      refute_nil base['delimiter']
      refute_nil base['precision']

      base = base_original[name]['number']['currency']['format']
      refute_nil base['format']
      refute_nil base['unit']
      refute_nil base['separator']
      refute_nil base['delimiter']
      refute_nil base['precision']
    end
  end
end
