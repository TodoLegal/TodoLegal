# ARGV = ['/home/deploy/tmp/output/']
# load 'scripts/reupload_full_gazettes.rb'

dir_path = ARGV[0]

Dir.foreach(dir_path) do |fname|
    break
    document = Document.where(name:"Gaceta", publication_number: fname).first
    if document
        puts document.issue_id
        document.original_file.attach(
            io: File.open(
                dir_path + fname
            ),
            filename: document.name + ".pdf",
            content_type: "application/pdf"
        )
    end
end