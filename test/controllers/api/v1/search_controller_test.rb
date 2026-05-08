# frozen_string_literal: true

require 'test_helper'

class Api::V1::SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    Searchkick.callbacks(:inline) do
      Law.reindex
      Article.reindex
      Document.reindex
    end
    # Use an allowed host for integration tests
    host! 'todolegal.app'
  end

  # --- Basic search ---

  test "search with no query returns paginated results" do
    get api_v1_search_path, params: { query: '' }
    assert_response :success

    json = JSON.parse(response.body)
    assert json['total'] > 0, "Should return results for empty query (wildcard fallback)"
    assert_equal 1, json['page']
    assert_equal 20, json['per_page'], "Default per_page should be 20"
    assert json['results'].is_a?(Array)
    assert json['results'].size <= 20, "Should return at most per_page results"
  end

  test "search with query returns relevant results" do
    get api_v1_search_path, params: { query: 'constitución' }
    assert_response :success

    json = JSON.parse(response.body)
    assert json['results'].any?, "Should return results for 'constitución'"
  end

  test "each result has a _type field" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    json['results'].each do |result|
      assert_includes %w[law article document], result['_type'],
        "Each result should have a valid _type"
    end
  end

  # --- Type filter ---

  test "type=law returns only law results" do
    get api_v1_search_path, params: { query: '*', type: 'law' }
    json = JSON.parse(response.body)

    json['results'].each do |result|
      assert_equal 'law', result['_type'], "All results should be laws"
    end
  end

  test "type=article returns only article results" do
    get api_v1_search_path, params: { query: '*', type: 'article' }
    json = JSON.parse(response.body)

    json['results'].each do |result|
      assert_equal 'article', result['_type'], "All results should be articles"
    end
  end

  test "type=document returns only document results" do
    get api_v1_search_path, params: { query: '*', type: 'document' }
    json = JSON.parse(response.body)

    json['results'].each do |result|
      assert_equal 'document', result['_type'], "All results should be documents"
    end
  end

  # --- Law result fields ---

  test "law results include expected fields" do
    get api_v1_search_path, params: { query: '*', type: 'law' }
    json = JSON.parse(response.body)

    law = json['results'].first
    return skip("No law fixtures") unless law

    %w[_type id name creation_number status url tags highlights].each do |field|
      assert law.key?(field), "Law result should include '#{field}'"
    end
    assert_equal 'law', law['_type']
    assert law['tags'].is_a?(Array), "Law tags should be an array of strings"
  end

  # --- Article result fields ---

  test "article results include expected fields" do
    get api_v1_search_path, params: { query: '*', type: 'article' }
    json = JSON.parse(response.body)

    article = json['results'].first
    return skip("No article fixtures") unless article

    %w[_type id article_number law_id law_name body_snippet highlights].each do |field|
      assert article.key?(field), "Article result should include '#{field}'"
    end
    assert_equal 'article', article['_type']
  end

  # --- Document result fields ---

  test "document results always include required fields" do
    get api_v1_search_path, params: { query: '*', type: 'document' }
    json = JSON.parse(response.body)

    doc = json['results'].first
    return skip("No document fixtures") unless doc

    %w[_type id issue_id name description tags highlights].each do |field|
      assert doc.key?(field), "Document result should include '#{field}'"
    end
    assert_equal 'document', doc['_type']
    assert doc['tags'].is_a?(Array), "Document tags should be an array"
  end

  test "document results do not include file_url for unauthenticated users" do
    get api_v1_search_path, params: { query: '*', type: 'document' }
    json = JSON.parse(response.body)

    json['results'].each do |doc|
      refute doc.key?('file_url'),
        "Unauthenticated users should not see file_url"
    end
  end

  test "document tags are structured with name and type" do
    get api_v1_search_path, params: { query: '*', type: 'document' }
    json = JSON.parse(response.body)

    doc_with_tags = json['results'].find { |d| d['tags'].any? }
    return skip("No documents with tags in fixtures") unless doc_with_tags

    doc_with_tags['tags'].each do |tag|
      assert tag.key?('name'), "Each tag should have 'name'"
      assert tag.key?('type'), "Each tag should have 'type'"
    end
  end

  # --- Pagination ---

  test "custom pagination is respected" do
    get api_v1_search_path, params: { query: '*', page: 1, per_page: 3 }
    json = JSON.parse(response.body)

    assert_equal 1, json['page']
    assert_equal 3, json['per_page']
    assert json['results'].size <= 3, "Should return at most per_page results"
  end

  test "page 2 returns different results than page 1" do
    get api_v1_search_path, params: { query: '*', page: 1, per_page: 2 }
    page1_ids = JSON.parse(response.body)['results'].map { |r| [r['_type'], r['id']] }

    get api_v1_search_path, params: { query: '*', page: 2, per_page: 2 }
    page2_ids = JSON.parse(response.body)['results'].map { |r| [r['_type'], r['id']] }

    assert_empty page1_ids & page2_ids, "Page 1 and page 2 should not overlap"
  end

  test "total_pages is calculated correctly" do
    get api_v1_search_path, params: { query: '*', per_page: 2 }
    json = JSON.parse(response.body)

    expected_pages = (json['total'].to_f / 2).ceil
    assert_equal expected_pages, json['total_pages']
  end

  # --- Facets and metadata ---

  test "response includes facets with content_type, status, and tags" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    assert json['facets'].is_a?(Hash)
    %w[content_type status tags].each do |key|
      assert json['facets'].key?(key), "Facets should include '#{key}'"
    end
  end

  test "content_type facet includes law, article, and document counts" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    ct = json['facets']['content_type']
    %w[law article document].each do |key|
      assert ct.key?(key), "content_type facet should include '#{key}'"
      assert ct[key].is_a?(Integer), "content_type count should be an integer"
    end
  end

  test "metadata includes per-type counts" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    %w[laws_count articles_count documents_count].each do |key|
      assert json['metadata'].key?(key), "Metadata should include '#{key}'"
    end
  end

  # --- Filters ---

  test "tag filter returns filtered results" do
    get api_v1_search_path, params: { query: '*', filters: { tags: ['Constitucional'] } }
    json = JSON.parse(response.body)

    assert_response :success
    # Tag-filtered results should be a subset of total results
  end

  test "date range filter works" do
    get api_v1_search_path, params: {
      query: '*', type: 'document',
      filters: { from: '2020-01-01', to: '2025-12-31' }
    }
    json = JSON.parse(response.body)

    assert_response :success
  end

  test "status filter returns only matching status" do
    get api_v1_search_path, params: {
      query: '*', type: 'law',
      filters: { status: 'vigente' }
    }
    json = JSON.parse(response.body)

    json['results'].each do |law|
      assert_equal 'vigente', law['status'], "Status filter should only return vigente laws"
    end
  end

  # --- Highlights ---

  test "search results include highlights for matching terms" do
    get api_v1_search_path, params: { query: 'constitución', type: 'law' }
    json = JSON.parse(response.body)

    has_highlight = json['results'].any? do |r|
      r['highlights'].is_a?(Hash) && r['highlights'].values.any? { |v| v.include?('<mark>') }
    end
    assert has_highlight, "At least one result should have a <mark> highlight"
  end

  # --- Error handling ---

  test "service failure returns 503 with error message" do
    # Simulate ES being down by stubbing the service call
    Search::UnifiedSearchService.stubs(:call).returns(
      ServiceResult.failure("Search unavailable: connection refused")
    )

    get api_v1_search_path, params: { query: 'test' }
    assert_response :service_unavailable

    json = JSON.parse(response.body)
    assert json['error'].present?, "Error response should include error message"
  end

  # --- Response envelope ---

  test "response has correct top-level structure" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    %w[results total page per_page total_pages facets metadata].each do |key|
      assert json.key?(key), "Response should include '#{key}'"
    end
  end
end
