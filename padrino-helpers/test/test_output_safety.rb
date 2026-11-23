require File.expand_path('helper', __dir__)

describe 'Padrino::SafeBuffer mutations' do
  it 'should escape plain strings passed to insert' do
    buffer = Padrino::SafeBuffer.new('<p></p>')
    buffer.insert(3, '<b>x</b>')
    assert_equal '<p>&lt;b&gt;x&lt;/b&gt;</p>', buffer
    assert_predicate buffer, :html_safe?

    safe = Padrino::SafeBuffer.new('<p></p>')
    safe.insert(3, Padrino::SafeBuffer.new('<b>x</b>'))
    assert_equal '<p><b>x</b></p>', safe
    assert_predicate safe, :html_safe?
  end

  it 'should escape plain strings passed to []=' do
    buffer = Padrino::SafeBuffer.new('<p>X</p>')
    buffer['X'] = '<b>x</b>'
    assert_equal '<p>&lt;b&gt;x&lt;/b&gt;</p>', buffer
    assert_predicate buffer, :html_safe?

    indexed = Padrino::SafeBuffer.new('<p>X</p>')
    indexed[3, 1] = '<i>y</i>'
    assert_equal '<p>&lt;i&gt;y&lt;/i&gt;</p>', indexed
    assert_predicate indexed, :html_safe?

    safe = Padrino::SafeBuffer.new('<p>X</p>')
    safe['X'] = Padrino::SafeBuffer.new('<b>x</b>')
    assert_equal '<p><b>x</b></p>', safe
    assert_predicate safe, :html_safe?
  end

  it 'should escape plain strings passed to replace' do
    buffer = Padrino::SafeBuffer.new('<p></p>')
    buffer.replace('<b>x</b>')
    assert_equal '&lt;b&gt;x&lt;/b&gt;', buffer
    assert_predicate buffer, :html_safe?

    safe = Padrino::SafeBuffer.new('<p></p>')
    safe.replace(Padrino::SafeBuffer.new('<b>x</b>'))
    assert_equal '<b>x</b>', safe
    assert_predicate safe, :html_safe?
  end

  it 'should clear html_safe? on setbyte' do
    buffer = Padrino::SafeBuffer.new('<p>X</p>')
    buffer.setbyte(3, 60)
    assert_equal '<p><</p>', buffer
    refute_predicate buffer, :html_safe?
  end

  it 'should clear html_safe? on bytesplice' do
    skip 'String#bytesplice not defined' unless String.method_defined?(:bytesplice)

    buffer = Padrino::SafeBuffer.new('<p>X</p>')
    buffer.bytesplice(3, 1, '<b>x</b>')
    refute_predicate buffer, :html_safe?
  end

  it 'should clear html_safe? on append_as_bytes' do
    skip 'String#append_as_bytes not defined' unless String.method_defined?(:append_as_bytes)

    buffer = Padrino::SafeBuffer.new('<p>')
    buffer.append_as_bytes('<b>x</b>', 33)
    assert_equal '<p><b>x</b>!', buffer
    refute_predicate buffer, :html_safe?
  end

  it 'should clear html_safe? for delete_prefix, delete_suffix, scrub, unicode_normalize and encode' do
    refute_predicate Padrino::SafeBuffer.new('<a>').delete_prefix('<'), :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').delete_suffix('>'), :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').scrub, :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').unicode_normalize, :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').encode('UTF-8', invalid: :replace), :html_safe?

    buf1 = Padrino::SafeBuffer.new('<a>')
    buf1.delete_prefix!('<')
    refute_predicate buf1, :html_safe?

    buf2 = Padrino::SafeBuffer.new('<a>')
    buf2.delete_suffix!('>')
    refute_predicate buf2, :html_safe?

    buf3 = Padrino::SafeBuffer.new('<a>')
    buf3.scrub!
    refute_predicate buf3, :html_safe?

    buf4 = Padrino::SafeBuffer.new('<a>')
    buf4.unicode_normalize!
    refute_predicate buf4, :html_safe?

    buf5 = Padrino::SafeBuffer.new('<a>')
    buf5.encode!('UTF-8', invalid: :replace)
    refute_predicate buf5, :html_safe?
  end
end
