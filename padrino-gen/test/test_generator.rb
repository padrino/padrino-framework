require_relative 'helper'

describe 'Generator' do
  describe 'the generator' do
    it 'should have default generators' do
      %w[controller mailer migration model app plugin component task helper].each do |gen|
        assert Padrino::Generators.mappings.key?(gen.to_sym)
        assert_equal "Padrino::Generators::#{gen.camelize}", Padrino::Generators.mappings[gen.to_sym].name
        assert_respond_to Padrino::Generators.mappings[gen.to_sym], :start
      end
    end
  end

  describe 'already_exists?' do
    before do
      @actions = Padrino::Generators::Model.new(['sample'])
      @dir = Dir.mktmpdir
    end

    after do
      Object.send(:remove_const, :AutoloadedSample) if Object.const_defined?(:AutoloadedSample, false)
      FileUtils.rm_rf(@dir)
    end

    it 'should reject a name that is not a constant with a usage error' do
      error = assert_raises(Thor::Error) { @actions.send(:already_exists?, '2bad') }
      assert_equal '2bad is not a valid constant name', error.message
    end

    it 'should let a NameError from autoloaded code through' do
      File.write("#{@dir}/autoloaded_sample.rb", "module AutoloadedSample; class Post; MissingThing; end; end\n")
      Object.autoload(:AutoloadedSample, "#{@dir}/autoloaded_sample.rb")
      error = assert_raises(NameError) { @actions.send(:already_exists?, 'AutoloadedSample::Post::Comment') }
      assert_match(/MissingThing/, error.message)
    end
  end
end
