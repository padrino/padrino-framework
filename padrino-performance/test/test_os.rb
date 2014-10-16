require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Padrino Performance OS Module" do
  WINDOWS_RELATED_SYSTEMS = %w(cygwin mswin mingw bccwin wince emx)

  describe "#windows?" do
    it 'should return false if OS is now windows' do
      RbConfig::CONFIG['target_os'] = "linux"
      refute(Padrino::Performance::OS.windows?, "No non windows system given")
    end

    it 'should return true if we have some windows instance' do
      WINDOWS_RELATED_SYSTEMS.each do |system|
        RbConfig::CONFIG['target_os'] = system
        assert(Padrino::Performance::OS.windows?, "#{system} is no windows related operation system.")
      end
    end
  end

  describe "#mac?" do
    it 'should return true if we have darwin running' do
      RbConfig::CONFIG['target_os'] = 'darwin'
      assert(Padrino::Performance::OS.mac?, "We have no Mac related system running")
    end

    it 'should return false if we have linux running' do
      RbConfig::CONFIG['target_os'] = 'linux'
      refute(Padrino::Performance::OS.mac?, "We have no Mac related system running")
    end
  end

  describe "#unix?" do
    it 'should return true if OS is not windows' do
      RbConfig::CONFIG['target_os'] = 'linux'
      assert(Padrino::Performance::OS.unix?, "We have no windows related system running")
    end

    it 'should return false if OS is windows' do
      WINDOWS_RELATED_SYSTEMS.each do |system|
        RbConfig::CONFIG['target_os'] = system
        refute(Padrino::Performance::OS.unix?, "#{system} is windows related operation system.")
      end
    end
  end

  describe "#linux?" do
    it 'should return true if we have no Windows or Mac related OS' do
      RbConfig::CONFIG['target_os'] = 'linux'
      assert(Padrino::Performance::OS.linux?, 'We have either Mac or Windows operation system.')
    end

    it 'should return false if we have a Windows or Mac related OS' do
      RbConfig::CONFIG['target_os'] = 'mingw'
      refute(Padrino::Performance::OS.linux?, 'We a Windows related operation system.')

      RbConfig::CONFIG['target_os'] = 'darwin'
      refute(Padrino::Performance::OS.linux?, 'We a darwin operation system.')
    end
  end
end
