require_relative 'helper'
require 'tmpdir'
require 'padrino-core/cli/binstub'

describe 'Padrino.replace_with_binstub' do
  it 'should tell the user to generate binstubs with bundle binstubs --all' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), '')
      File.write(File.join(dir, '.components'), '')
      out, = capture_io do
        Bundler.stub(:definition, -> { raise Bundler::GemfileNotFound }) do
          Padrino.stub(:exit!, nil) do
            Dir.chdir(dir) { Padrino.replace_with_binstub('padrino') }
          end
        end
      end
      assert_match(/bundle install && bundle binstubs --all/, out)
      refute_match(/--binstubs/, out)
    end
  end
end
