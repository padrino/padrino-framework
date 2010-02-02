class Uploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support
  #   include CarrierWave::RMagick
  #   include CarrierWave::ImageScience
  #   include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader
  storage :file
  #     storage :s3

  # Override the directory where uploaded files will be stored (default is /public/uploads)
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads"
  end

  def cache_dir
    "tmp"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded
  #     def default_url
  #       "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  #     end
  # Process files as they are uploaded.
  # process :resize_to_fit => [640, 480]
  #
  #     def scale(width, height)
  #       # do something
  #     end

  # Create different versions of your uploaded files
  # version :thumb do
  #   process :resize_to_fit => [128, 128]
  # end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files
  #     def filename
  #       "something.jpg" if original_filename
  #     end

end