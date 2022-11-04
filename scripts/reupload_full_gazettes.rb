# ARGV = ['/home/deploy/tmp/output/']
# load 'scripts/reupload_full_gazettes.rb'

dir_path = ARGV[0]

Dir.foreach(dir_path) do |fname|
    document = Document.where(name:"Gaceta", publication_number: fname).first
    if document
        puts "Reuploading: " + document.publication_number
        document.original_file.attach(
            io: File.open(
                dir_path + fname
            ),
            filename: document.name + ".pdf",
            content_type: "application/pdf"
        )
    else
        puts fname + " not found."
    end
end