require 'test_helper'

class Search::UnifiedSearchServiceTest < ActiveSupport::TestCase
  setup do
    Searchkick.callbacks(:inline) do
      Law.reindex
      Article.reindex
      Document.reindex
    end
  end

  # Helper: extract flat result sources from the service result
  def results_from(service_result)
    service_result.data[:results_with_highlights].map { |source, _highlights| source }
  end

  # Helper: determine model type from ES _index name
  def index_type(source)
    case source._index.to_s
    when /\Alaws_/      then :law
    when /\Aarticles_/   then :article
    when /\Adocuments_/  then :document
    end
  end

  # --- Multi-model search ---

  test "returns a successful ServiceResult" do
    result = Search::UnifiedSearchService.call(query: "*")
    assert result.success?, "Should return a successful ServiceResult"
    assert result.data.is_a?(Hash), "Data should be a Hash"
  end

  test "search returns results from multiple model types" do
    result = Search::UnifiedSearchService.call(query: "constitución")
    sources = results_from(result)
    assert sources.any?, "Should return at least one result"
    types = sources.map { |s| index_type(s) }.uniq
    assert types.include?(:law) || types.include?(:article),
      "Results should include law or article types"
  end

  test "wildcard query returns results from all indexed models" do
    result = Search::UnifiedSearchService.call(query: "*")
    assert result.data[:total] > 0, "Wildcard should return results"
  end

  test "results are Searchkick::HashWrapper (load: false)" do
    result = Search::UnifiedSearchService.call(query: "*")
    sources = results_from(result)
    sources.each do |s|
      assert_kind_of Searchkick::HashWrapper, s, "Results should be HashWrapper, not AR records"
    end
  end

  # --- Type filter ---

  test "type filter 'law' returns only Law results" do
    result = Search::UnifiedSearchService.call(query: "constitución", type: "law")
    results_from(result).each do |s|
      assert_equal :law, index_type(s), "All results should be laws when type=law"
    end
  end

  test "type filter 'article' returns only Article results" do
    result = Search::UnifiedSearchService.call(query: "soberanía", type: "article")
    results_from(result).each do |s|
      assert_equal :article, index_type(s), "All results should be articles when type=article"
    end
  end

  test "type filter 'document' returns only Document results" do
    result = Search::UnifiedSearchService.call(query: "*", type: "document")
    results_from(result).each do |s|
      assert_equal :document, index_type(s), "All results should be documents when type=document"
    end
  end

  test "invalid type filter falls back to all models" do
    result = Search::UnifiedSearchService.call(query: "*", type: "invalid")
    assert result.data[:total] > 0, "Should still return results with invalid type"
  end

  # --- Status filter ---

  test "status filter 'vigente' returns only vigente laws" do
    result = Search::UnifiedSearchService.call(query: "*", type: "law", filters: { status: "vigente" })
    results_from(result).each do |s|
      assert_equal "vigente", s.status, "All laws should be vigente"
    end
  end

  test "status filter 'derogado' returns only derogado laws" do
    result = Search::UnifiedSearchService.call(query: "*", type: "law", filters: { status: "derogado" })
    results_from(result).each do |s|
      assert_equal "derogado", s.status, "All laws should be derogado"
    end
  end

  # --- Tag filter ---

  test "tag filter returns results matching the tag" do
    result = Search::UnifiedSearchService.call(query: "*", filters: { tags: ["Constitucional"] })
    assert results_from(result).any?, "Should find results tagged 'Constitucional'"
  end

  # --- Date parsing integration ---

  test "Spanish date query is parsed and used for search" do
    result = Search::UnifiedSearchService.call(query: "20 de abril del 2020")
    assert result.success?, "Should return a successful result"
    assert result.data.key?(:results_with_highlights), "Should return a valid response"
  end

  # --- Pagination ---

  test "pagination defaults to page 1 and 20 per page" do
    result = Search::UnifiedSearchService.call(query: "*")
    assert_equal 1, result.data[:page]
    assert_equal 20, result.data[:per_page]
  end

  test "custom pagination is respected" do
    result = Search::UnifiedSearchService.call(query: "*", page: 2, per_page: 5)
    assert_equal 2, result.data[:page]
    assert_equal 5, result.data[:per_page]
  end

  test "per_page is clamped to MAX_PER_PAGE" do
    result = Search::UnifiedSearchService.call(query: "*", per_page: 500)
    assert_equal 100, result.data[:per_page]
  end

  test "total_pages is calculated correctly" do
    result = Search::UnifiedSearchService.call(query: "*", per_page: 2)
    expected_pages = (result.data[:total].to_f / 2).ceil
    assert_equal expected_pages, result.data[:total_pages]
  end

  # --- Response structure ---

  test "response includes all expected top-level keys" do
    result = Search::UnifiedSearchService.call(query: "*")
    %i[results_with_highlights total page per_page total_pages facets metadata].each do |key|
      assert result.data.key?(key), "Data should include :#{key}"
    end
  end

  test "facets include content_type, status, and tags" do
    result = Search::UnifiedSearchService.call(query: "*")
    %i[content_type status tags].each do |key|
      assert result.data[:facets].key?(key), "Facets should include :#{key}"
    end
  end

  test "content_type facet has law, article, and document keys" do
    result = Search::UnifiedSearchService.call(query: "*")
    %i[law article document].each do |key|
      assert result.data[:facets][:content_type].key?(key),
        "content_type facet should include :#{key}"
    end
  end

  test "metadata includes per-type counts" do
    result = Search::UnifiedSearchService.call(query: "*")
    %i[laws_count articles_count documents_count].each do |key|
      assert result.data[:metadata].key?(key), "Metadata should include :#{key}"
    end
  end

  # --- Highlighting ---

  test "search results include highlights for matching terms" do
    result = Search::UnifiedSearchService.call(query: "constitución", type: "law")
    has_highlight = result.data[:results_with_highlights].any? do |_source, highlights|
      highlights.present? && highlights.values.any? { |v| v.include?("<mark>") }
    end
    assert has_highlight, "At least one result should have a <mark> highlight"
  end

  # --- Edge cases ---

  test "blank query defaults to wildcard" do
    result = Search::UnifiedSearchService.call(query: "")
    assert result.data[:total] > 0, "Blank query should default to wildcard and return results"
  end

  test "nil query defaults to wildcard" do
    result = Search::UnifiedSearchService.call(query: nil)
    assert result.data[:total] > 0, "Nil query should default to wildcard and return results"
  end

  test "unpublished documents are excluded from mixed search results" do
    result = Search::UnifiedSearchService.call(query: "*")
    doc_sources = results_from(result).select { |s| index_type(s) == :document }
    doc_sources.each do |s|
      assert s.publish, "Unpublished documents should not appear in results"
    end
  end
end
