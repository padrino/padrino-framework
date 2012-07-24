require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Filters" do
  Dir[File.expand_path("../../lib/padrino-admin/locale/admin/*.yml", __FILE__)].each do |file|
    name = File.basename(file, '.yml')
    should "have a vaild #{name} locale for admin" do
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

  Dir[File.expand_path("../../lib/padrino-admin/locale/orm/*.yml", __FILE__)].each do |file|
    name = File.basename(file, '.yml')
    should "have a vaild #{name} locale for orm" do
      base = YAML.load_file(file)
      # TODO: some one can know why I can't parse YML aliases?
      %w(activemodel).each do |m|
        base = base[name][m]['errors']['messages']
        assert base.present?
        assert base['inclusion'].present?
        assert base['exclusion'].present?
        assert base['invalid'].present?
        assert base['confirmation'].present?
        assert base['accepted'].present?
        assert base['empty'].present?
        assert base['blank'].present?
        assert base['too_long'].present?
        assert base['too_short'].present?
        assert base['wrong_length'].present?
        assert base['taken'].present?
        assert base['not_a_number'].present?
        assert base['greater_than'].present?
        assert base['greater_than_or_equal_to'].present?
        assert base['equal_to'].present?
        assert base['less_than'].present?
        assert base['less_than_or_equal_to'].present?
        assert base['odd'].present?
        assert base['even'].present?
        assert base['record_invalid'].present?
        assert base['content_type'].present?
      end
    end
  end
end
