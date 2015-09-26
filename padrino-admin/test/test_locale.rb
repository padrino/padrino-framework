require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Filters" do
  Dir[File.expand_path("../../lib/padrino-admin/locale/admin/*.yml", __FILE__)].each do |file|
    name = File.basename(file, '.yml')
    it "should have a vaild #{name} locale for admin" do
      base = YAML.load_file(file)
      base = base[name]['padrino']['admin']
      assert base.present?
      assert base['save'].present?
      assert base['cancel'].present?
      assert base['list'].present?
      assert base['edit'].present?
      assert base['new'].present?
      assert base['show'].present?
      assert base['delete'].present?
      assert base['confirm'].present?
      assert base['created_at'].present?
      assert base['all'].present?
      assert base['profile'].present?
      assert base['settings'].present?
      assert base['logout'].present?
    end
  end
end
