class Versioner
  attr_accessor :current_version

  def initialize(current_version, version_files)
    @current_version = current_version
    @version_files = version_files
  end

  def bump!(kind)
    @current_version = Versionomy.parse(@current_version).bump(kind).to_s
    @version_files.each { |file| File.open(file, 'w') { |f| f.puts @current_version } }
    @current_version
  end
end