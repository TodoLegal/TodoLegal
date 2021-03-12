file_path = ARGV[0]
puts "Loading.."
puts file_path
document_controller = DocumentsController.new
@document = Document.create
document_controller.run_gazette_script @document, file_path
puts "Loaded!"