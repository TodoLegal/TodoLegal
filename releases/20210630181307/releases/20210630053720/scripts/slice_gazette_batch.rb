#how to run:
#ARGV = ['/home/turupawn/Projects/Gacetas/']
#load 'scripts/slice_gazette_batch.rb'
dir_path = ARGV[0]
Dir.each_child(dir_path) {
    |filename|
    puts "Loading.."
    ARGV[0] = "\"" + dir_path + filename + "\""
    load 'scripts/slice_gazette.rb'
    puts "Loaded!"
}
