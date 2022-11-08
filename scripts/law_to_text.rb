#how to run:
#ARGV = ['/home/turupawn/Projects/Gacetas/']
#load 'scripts/add_gazette_batch.rb'

require 'fileutils'

arg_id = ARGV[0]
arg_directory = ARGV[1]

@law = Law.find_by_id(arg_id)

puts "Exporting: " + @law.name

@books = @law.books.order(:position)
@titles = @law.titles.order(:position)
@chapters = @law.chapters.order(:position)
@sections = @law.sections.order(:position)
@subsections = @law.subsections.order(:position)
@articles = @law.articles.order(:position)

application_controller = ApplicationController.new
get_law_stream_return_values = application_controller.get_law_stream @law, @books, @chapters, @sections, @subsections, @articles, @titles, nil

@stream = get_law_stream_return_values[0]
@result_index_items = get_law_stream_return_values[1]
@result_go_to_article = get_law_stream_return_values[2]
@has_articles_only = get_law_stream_return_values[3]

result = ""

@stream.each do |s|
    if s.instance_of? Book
        result+= "Libro "
        result+= s.number if s.number
        result+= ": "
        result+= s.name if s.name
        result+= "\n"
    end
    if s.instance_of? Title
        result+= "Título "
        result+= s.number if s.number
        result+= ": "
        result+= s.name if s.name
        result+= "\n"
    end
    if s.instance_of? Chapter
        result+= "Capítulo "
        result+= s.number if s.number
        result+= ": "
        result+= s.name if s.name
        result+= "\n"
    end
    if s.instance_of? Section
        result+= "Sección "
        result+= s.number if s.number
        result+= ": "
        result+= s.name if s.name
        result+= "\n"
    end
    if s.instance_of? Subsection
        result+= "Subsección "
        result+= s.number if s.number
        result+= ": "
        result+= s.name if s.name
        result+= "\n"
    end
    if s.instance_of? Article
        result+= "Artículo " + s.number + "\n" + s.body + "\n"
    end
end

@law.materia_names.each do |law_materia|
    FileUtils.mkdir_p(arg_directory)
    FileUtils.mkdir_p(arg_directory + law_materia)
    File.open(arg_directory + law_materia + "/" + @law.name[0, 20], 'w') { |file| file.write(result) }
end