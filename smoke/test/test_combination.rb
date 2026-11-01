require_relative 'helper'

describe 'Smoke::Combination' do
  let(:combos) { Smoke::Combination.load }
  let(:components_dir) { File.expand_path('../../padrino-gen/lib/padrino-gen/generators/components', __dir__) }

  def combo(attrs)
    Smoke::Combination.new({ 'name' => 'fixture', 'orm' => 'sequel', 'adapter' => 'postgres', 'renderer' => 'haml',
                             'test' => 'minitest', 'mock' => 'mocha', 'script' => 'jquery', 'stylesheet' => 'scss',
                             'server' => 'puma' }.merge(attrs))
  end

  describe 'load' do
    it 'gives every combination a unique name' do
      names = combos.map(&:name)
      assert_equal names.uniq, names
    end

    it 'names only components that exist' do
      types = { 'orm' => 'orms', 'renderer' => 'renderers', 'test' => 'tests', 'mock' => 'mocks',
                'script' => 'scripts', 'stylesheet' => 'stylesheets' }
      combos.each do |c|
        types.each do |attr, dir|
          value = c.public_send(attr)
          next if value == 'none'
          assert File.file?(File.join(components_dir, dir, "#{value}.rb")), "#{c.name}: no #{dir}/#{value}.rb"
        end
      end
    end
  end

  it 'covers every component and pair' do
    assert_empty Smoke::Combination.coverage_gaps(combos)
  end

  it 'reports a missing pair' do
    dropped = combos.find { |c| c.orm == 'sequel' && c.renderer == 'liquid' }
    refute_nil dropped
    gaps = Smoke::Combination.coverage_gaps(combos - [dropped])
    assert_includes gaps, 'orm x renderer: sequel x liquid'
  end

  it 'derives admin?' do
    refute combo('orm' => 'none', 'adapter' => nil).admin?
    refute combo('renderer' => 'liquid').admin?
    assert combo({}).admin?
  end

  it 'builds generator flags' do
    assert_equal %w[--orm=sequel --adapter=postgres --renderer=haml --test=minitest --mock=mocha
                    --script=jquery --stylesheet=scss --server=puma], combo({}).generator_flags
    refute(combo('orm' => 'mongoid', 'adapter' => nil).generator_flags.any? { |f| f.start_with?('--adapter') })
  end

  it 'adds the project shape to the generator flags, not the component flags' do
    assert_includes combo('shape' => 'tiny').generator_flags, '--tiny'
    refute_includes combo('shape' => 'tiny').component_flags, '--tiny'
    assert_equal combo({}).generator_flags.size + 1, combo('shape' => 'api').generator_flags.size
  end

  it 'reports a missing project shape' do
    gaps = Smoke::Combination.coverage_gaps(combos.reject { |c| c.shape == 'tiny' })
    assert_includes gaps, 'shape: tiny'
  end

  it 'never expects a lean or api project to take an admin' do
    refute combo('shape' => 'lean').admin?
    refute combo('shape' => 'api').admin?
    assert combo('shape' => 'tiny').admin?
  end

  it 'leaves the server out of component flags' do
    assert_equal %w[--orm=sequel --adapter=postgres --renderer=haml --test=minitest --mock=mocha
                    --script=jquery --stylesheet=scss], combo({}).component_flags
  end

  it 'rejects unknown names' do
    error = assert_raises(ArgumentError) { Smoke::Combination.find('nope') }
    assert_includes error.message, combos.first.name
  end
end
