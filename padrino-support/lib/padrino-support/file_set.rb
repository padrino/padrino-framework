##
# FileSet helper method for iterating and interacting with files inside a directory
#
module FileSet
  extend self
  ##
  # Iterates over every file in the glob pattern and yields to a block
  # Returns the list of files matching the glob pattern
  # FileSet.glob('padrino-core/application/*.rb', __FILE__) { |file| load file }
  #
  def glob(glob_pattern, file_path=nil)
    glob_pattern = File.join(File.dirname(file_path), glob_pattern) if file_path
    file_list = Dir.glob(glob_pattern).sort
    file_list.each{ |file| yield(file) }
    file_list
  end

  ##
  # Requires each file matched in the glob pattern into the application
  # FileSet.glob_require('padrino-core/application/*.rb', __FILE__)
  #
  def glob_require(glob_pattern, file_path=nil)
    glob(glob_pattern, file_path) { |f| require f }
  end
end
