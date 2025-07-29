
# Script to add new "Tema" tags to the database
# Run this in Rails console: load 'scripts/updates/add_new_tags.rb'

# Find or create the "Tema" tag type
tema_tag_type = TagType.find_by(name: "Tema")

# List of new tags to create
new_tags = [
  "Gestión de Activos",
  "Fondos de Pensiones y Previsión Social",
  "Servicios de Custodia y Almacenaje",
  "Expansión y Presencia Física",
  "Fomento Económico Sectorial",
  "Productos de Arrendamiento",
  "Calendario y Jornadas Laborales",
  "Procesos de Auditoría y Control",
  "Mercados Bursátiles",
  "Información Crediticia",
  "Estructura Patrimonial",
  "Sistemas de Información Regulatoria",
  "Gestión de Créditos",
  "Depósitos e Instrumentos de Ahorro",
  "Transparencia e Información",
  "Pagos y Transferencias",
  "Supervisión y Regulación",
  "Inversiones y Mercados",
  "Gobierno y Administración",
  "Apoyo y Desarrollo",
  "Varios"
]

puts "Creating tags of type 'Tema'..."
created_count = 0
skipped_count = 0

new_tags.each do |tag_name|
  tag = Tag.find_or_create_by(name: tag_name, tag_type: tema_tag_type)
  
  if tag.persisted? && tag.created_at == tag.updated_at
    puts "✓ Created: #{tag_name}"
    created_count += 1
  else
    puts "⚠ Skipped (already exists): #{tag_name}"
    skipped_count += 1
  end
end

puts "\n=== Summary ==="
puts "Tags created: #{created_count}"
puts "Tags skipped: #{skipped_count}"
puts "Total tags processed: #{new_tags.length}"
puts "\nScript completed successfully!"