class Document < ApplicationRecord
  has_one_attached :original_file

  def original_file_path
    ActiveStorage::Blob.service.path_for(original_file.key)
  end
end
