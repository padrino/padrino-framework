class Uploader < CarrierWave::Uploader::Base

  ##
  # Image manipulator library:
  #
  # include CarrierWave::RMagick
  # include CarrierWave::ImageScience
  # include CarrierWave::MiniMagick

  ##
  # Storage type
  # 
  storage :file
  # storage :s3

  ##
  # Directory where uploaded files will be stored (default is /public/uploads)
  # 
  def store_dir
    "uploads"
  end

  ##
  # Directory where uploaded temp files will be stored (default is /public/temp)
  # 
  def cache_dir
    "tmp"
  end

  ##
  # Default URL as a default if there hasn't been a file uploaded
  # 
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  ##
  # Process files as they are uploaded.
  # 
  # process :resize_to_fit => [640, 480]
  #
  # def scale(width, height)
  #   # do something
  # end

  ##
  # Create different versions of your uploaded files
  # 
  # version :thumb do
  #   process :resize_to_fit => [128, 128]
  # end

  ##
  # White list of extensions which are allowed to be uploaded:
  # 
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  ##
  # Override the filename of the uploaded files
  # 
  # def filename
  #   "something.jpg" if original_filename
  # end
end