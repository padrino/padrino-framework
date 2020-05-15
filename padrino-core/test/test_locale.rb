require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Locales" do
  Dir[File.expand_path("../../lib/padrino-core/locale/*.yml", __FILE__)].each do |file|
    base_original = YAML.load_file(file)
    name = File.basename(file, '.yml')
    it "should should have correct locale for #{name}" do
      base = base_original[name]['date']['formats']
      assert base['default']
      assert base['short']
      assert base['long']
      assert base['only_day']
      base = base_original[name]['date']
      assert base['day_names']
      assert base['abbr_day_names']
      assert base['month_names']
      assert base['abbr_month_names']
      assert base['order']
    end
  end
end
