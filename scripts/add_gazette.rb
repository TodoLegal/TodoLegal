#how to run:
#ARGV = ['/home/turupawn/Projects/Gacetas/gazette.pdf']
#load 'scripts/add_gazette.rb'

file_path = ARGV[0]
puts "Loading.."
puts file_path
document_controller = DocumentsController.new
@document = Document.create(document_type_id: DocumentType.find_by_name("Gaceta").id)
document_controller.slice_gazette @document, '"' + file_path + '"'
puts "A"
@document.original_file.attach(
    io: File.open(
      file_path
    ),
    filename: @document.name + ".pdf",
    content_type: "application/pdf"
  )
puts "B"
document_controller.set_content_disposition_attachment @document.original_file.key, @document.name + ".pdf"
puts "Loaded!"
