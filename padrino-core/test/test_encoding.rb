# encoding: UTF-8
require File.expand_path('../helper', __FILE__)
require 'erb'

describe 'Encoding' do
  let(:base) do
    Padrino.new { set :views, File.dirname(__FILE__) + '/views' }
  end

  it 'allows unicode strings in ascii templates per default (1.9)' do
    base.new!.erb(File.read(base.views + '/ascii.erb').encode('ASCII'), {}, :value => 'åkej')
  end

  it 'allows ascii strings in unicode templates per default (1.9)' do
    base.new!.erb(:utf8, {}, :value => 'Some Lyrics'.encode('ASCII'))
  end
end
