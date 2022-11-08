# usage
# ARGV = ['/home/turupawn/Projects/Gacetas/']
# load 'scripts/add_gazette_batch.rb'
dir_path = ARGV[0]
Dir.each_child(dir_path) {
    |filename|
    puts "Loading.."
    ARGV[0] = dir_path + filename
    load 'scripts/add_gazette.rb'
    puts "Loaded!"
}