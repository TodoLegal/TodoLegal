# One-liner script for Rails console
# Copy and paste this into rails console or save as a .rb file

# Simple version - returns JSON string
laws_json = Law.includes(law_tags: { tag: :tag_type }).map do |law|
  materia_tags = law.tags.joins(:tag_type).where(tag_types: { name: 'materia' })
  {
    id: law.id,
    name: law.name,
    url_slug: law.friendly_url,
    full_url: "https://todolegal.app/laws/#{law.friendly_url}",
    materia_type_tag_names: materia_tags.pluck(:name),
    creation_number: law.creation_number,
    revision_date: law.updated_at&.strftime('%Y-%m-%d')
  }
end

# Output the JSON
puts JSON.pretty_generate({
  export_date: Time.current.strftime('%Y-%m-%d %H:%M:%S'),
  total_laws: laws_json.count,
  laws: laws_json
})

# If you want to save to a variable for further processing:
# laws_data = laws_json
