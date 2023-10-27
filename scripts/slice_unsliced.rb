open('log/script.log', 'a') do |f|
    f << "Initializing slice unsliced gazettes script\n"
end

@gazette_publication_numbers=[]
Document.all.group_by(&:publication_number).each do |gouped_gazette|
  if !gouped_gazette.first.blank?
    has_original = false
    is_sliced = false
    gouped_gazette.second.each do |gazette_document|
        if gazette_document.name == "Gaceta"
            has_original = true
        else
            is_sliced = true
        end
    end
    @gazette_publication_numbers.push({publication_number: gouped_gazette.first, has_original: has_original, is_sliced: is_sliced})
  end
end
puts "Gazette numbers stored in @gazette_publication_numbers"

open('log/script.log', 'a') do |f|
    f << "@gazette_publication_numbers:\n"
    f << @gazette_publication_numbers
    f << "\n"
end

@not_sliced_gazettes=[]
@gazette_publication_numbers.each do |gazette|
    if !gazette[:is_sliced]
        @not_sliced_gazettes.push(gazette[:publication_number])
    end
end
puts "Not sliced gazettes stored in @not_sliced_gazettes"

open('log/script.log', 'a') do |f|
    f << "@not_sliced_gazettes:\n"
    f << @not_sliced_gazettes
    f << "\n"
end

@not_sliced_gazettes_document=[]
@not_sliced_gazettes.each do |gazette|
    @not_sliced_gazettes_document.push(Document.find_by_publication_number(gazette))
    puts Document.find_by_publication_number(gazette).name
end
puts "Not sliced gazettes stored in @not_sliced_gazettes_document"

open('log/script.log', 'a') do |f|
    f << "@not_sliced_gazettes_document:\n"
    f << @not_sliced_gazettes_document
    f << "\n"
end

require "google/cloud/storage"
storage = Google::Cloud::Storage.new(project_id:"docs-tl", credentials: Rails.root.join("gcs.keyfile"))
@bucket = storage.bucket GCS_BUCKET

document_controller = DocumentsController.new

@not_sliced_gazettes_document.each do |document|
    file = @bucket.file document.original_file.key
    begin
        if file and !document.original_file.key.blank?
            file.download "tmp/gazette.pdf"
            puts document.name
            document_controller.run_slice_gazette_script document, "tmp/gazette.pdf"
        end
    rescue => e
        open('log/script.log', 'a') do |f|
            f << "Error: " << e << "\n"
        end
    end
end

open('log/script.log', 'a') do |f|
    f << "Finished slice unsliced gazettes script\n"
end