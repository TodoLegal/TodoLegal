#how to run:
#load 'scripts/law_to_text_batch.rb'
Law.all.each do |law|
    puts "Loading.."
    ARGV[0] = law.id
    ARGV[1] = "output/"
    load 'scripts/law_to_text.rb'
    puts "Loaded!"
end