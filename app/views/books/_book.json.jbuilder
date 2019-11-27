json.extract! book, :id, :number, :name, :position, :law_id, :created_at, :updated_at
json.url book_url(book, format: :json)
