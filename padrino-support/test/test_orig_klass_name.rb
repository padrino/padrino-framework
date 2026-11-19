require_relative 'helper'

describe 'Module#_orig_klass_name' do
  before do
    @warned = Padrino.instance_variable_defined?(:@_orig_klass_name_warned)
    Padrino.remove_instance_variable(:@_orig_klass_name_warned) if @warned
  end

  after do
    if @warned
      Padrino.instance_variable_set(:@_orig_klass_name_warned, true)
    elsif Padrino.instance_variable_defined?(:@_orig_klass_name_warned)
      Padrino.remove_instance_variable(:@_orig_klass_name_warned)
    end
  end

  it 'should warn once, naming the replacement and the caller, and return the name' do
    line = __LINE__ + 2
    _, err = capture_io do
      assert_equal 'Padrino::Utils', Padrino::Utils._orig_klass_name
      assert_equal 'String', String._orig_klass_name
    end
    assert_equal 1, err.scan('WARNING! Module#_orig_klass_name is deprecated').size
    assert_includes err, 'removed in Padrino 1.0'
    assert_includes err, 'Module.instance_method(:name).bind(mod).call'
    assert_includes err, "(called at #{__FILE__}:#{line})"
  end

  it 'should return the name Ruby gave a class that overrides name' do
    renamed = Class.new { def self.name; 'SomethingElse'; end }
    Object.const_set(:OrigKlassNameRenamed, renamed)
    capture_io do
      assert_equal 'OrigKlassNameRenamed', renamed._orig_klass_name
      assert_nil Module.new._orig_klass_name
    end
  ensure
    Object.send(:remove_const, :OrigKlassNameRenamed) if Object.const_defined?(:OrigKlassNameRenamed, false)
  end
end
