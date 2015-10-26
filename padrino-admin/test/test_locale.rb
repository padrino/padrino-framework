require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Filters" do
  Dir[File.expand_path("../../lib/padrino-admin/locale/admin/*.yml", __FILE__)].each do |file|
    name = File.basename(file, '.yml')
    it "should have a vaild #{name} locale for admin" do
      base = YAML.load_file(file)
      base = base[name]['padrino']['admin']
      assert base
      assert base['save']
      assert base['cancel']
      assert base['list']
      assert base['edit']
      assert base['new']
      assert base['show']
      assert base['delete']
      assert base['confirm']
      assert base['created_at']
      assert base['all']
      assert base['profile']
      assert base['settings']
      assert base['logout']
    end
  end
end
