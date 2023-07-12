
class CustomizeHighlightTest < Minitest::Test
    def test_highlighting_in_preview
      search_query = "example"
      pg_search_highlight = "This is an example sentence. Another example is here."
  
      highlighted_preview = customize_highlight(pg_search_highlight, [search_query])
  
      expected_preview = "This is an <span style='background-color: yellow;'>example</span> sentence. Another <span style='background-color: yellow;'>example</span> is here."
  
      assert_equal expected_preview, highlighted_preview
    end
  
    private
  
    def customize_highlight(text, search_words)
      highlighted_text = text
  
      search_words.each do |search_word|
        highlighted_text = highlighted_text.gsub(/(#{Regexp.escape(search_word)})/i, "<span style='background-color: yellow;'>\\1</span>")
      end
  
      highlighted_text.html_safe
    end
  end