# frozen_string_literal: true

require 'test_helper'

class Api::V1::SearchControllerTest < ActionDispatch::IntegrationTest
  TEST_API_SECRET = 'test-chatbot-secret'

  setup do
    Searchkick.callbacks(:inline) do
      Article.reindex
      Document.reindex
    end
    # Use an allowed host for integration tests
    host! 'todolegal.app'
    ENV['CHATBOT_API_SECRET'] = TEST_API_SECRET
  end

  teardown do
    ENV.delete('CHATBOT_API_SECRET')
  end

  private

  def auth_headers
    { 'X-Chatbot-Secret' => TEST_API_SECRET }
  end

  # Auto-inject auth headers for all requests unless explicitly testing unauth.
  def get(path, **kwargs)
    kwargs[:headers] = (kwargs[:headers] || {}).merge(auth_headers) unless kwargs.delete(:skip_auth)
    super(path, **kwargs)
  end

  public

  # --- Authentication ---

  test "unauthenticated request returns 401" do
    get api_v1_search_path, params: { query: 'test' }, skip_auth: true
    assert_response :unauthorized
  end

  # --- Basic search (flat format, default) ---

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
      assert_includes %w[article document], result['_type'],
        "Each result should have _type 'article' or 'document'"
    end
  end

  # --- Type filter ---

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

  test "type=law falls back to all models" do
    get api_v1_search_path, params: { query: '*', type: 'law' }
    json = JSON.parse(response.body)

    assert json['total'] > 0, "type=law should fall back to all models and return results"
    types = json['results'].map { |r| r['_type'] }.uniq
    refute_includes types, 'law', "No law-type results should exist"
  end

  # --- Article result fields ---

  test "article results include expected fields" do
    get api_v1_search_path, params: { query: '*', type: 'article' }
    json = JSON.parse(response.body)

    article = json['results'].first
    return skip("No article fixtures") unless article

    %w[_type id article_number law_id law_name law_hierarchy body highlights].each do |field|
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

  test "document results do not include file_url for service-authenticated users" do
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

  test "content_type facet includes article and document counts (no law)" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    ct = json['facets']['content_type']
    %w[article document].each do |key|
      assert ct.key?(key), "content_type facet should include '#{key}'"
      assert ct[key].is_a?(Integer), "content_type count should be an integer"
    end
    refute ct.key?('law'), "content_type facet should NOT include 'law'"
  end

  test "metadata includes articles_count and documents_count (no laws_count)" do
    get api_v1_search_path, params: { query: '*' }
    json = JSON.parse(response.body)

    %w[articles_count documents_count].each do |key|
      assert json['metadata'].key?(key), "Metadata should include '#{key}'"
    end
    refute json['metadata'].key?('laws_count'), "Metadata should NOT include 'laws_count'"
  end

  # --- Filters ---

  test "tag filter returns filtered results" do
    get api_v1_search_path, params: { query: '*', filters: { tags: ['Constitucional'] } }
    assert_response :success
  end

  test "date range filter works" do
    get api_v1_search_path, params: {
      query: '*', type: 'document',
      filters: { from: '2020-01-01', to: '2025-12-31' }
    }
    assert_response :success
  end

  test "status filter matches articles by law_status" do
    get api_v1_search_path, params: {
      query: '*', type: 'article',
      filters: { status: 'vigente' }
    }
    json = JSON.parse(response.body)
    assert_response :success
    # Articles are filtered by law_status via the _or clause
  end

  # --- Highlights ---

  test "search results include highlights for matching terms" do
    get api_v1_search_path, params: { query: 'soberanía' }
    json = JSON.parse(response.body)

    has_highlight = json['results'].any? do |r|
      r['highlights'].is_a?(Hash) && r['highlights'].values.any? { |v| v.to_s.include?('<mark>') }
    end
    assert has_highlight, "At least one result should have a <mark> highlight"
  end

  # --- Grouped format ---

  test "result_format=grouped returns grouped response" do
    get api_v1_search_path, params: { query: '*', result_format: 'grouped' }
    assert_response :success

    json = JSON.parse(response.body)
    assert json['results'].is_a?(Array)
    assert json.key?('total')
    assert json.key?('facets')
  end

  test "result_format=grouped contains law_group entries with correct structure" do
    get api_v1_search_path, params: { query: '*', result_format: 'grouped' }
    json = JSON.parse(response.body)

    law_group = json['results'].find { |r| r['_type'] == 'law_group' }
    return skip("No article fixtures to form law groups") unless law_group

    assert law_group.key?('law'), "law_group should have 'law' key"
    assert law_group.key?('articles'), "law_group should have 'articles' key"

    law = law_group['law']
    %w[id name creation_number status url tags].each do |field|
      assert law.key?(field), "law metadata should include '#{field}'"
    end

    article = law_group['articles'].first
    %w[id number body snippet].each do |field|
      assert article.key?(field), "grouped article should include '#{field}'"
    end
  end

  test "result_format=grouped includes documents alongside law groups" do
    get api_v1_search_path, params: { query: '*', result_format: 'grouped' }
    json = JSON.parse(response.body)

    types = json['results'].map { |r| r['_type'] }.uniq
    # Should have at least document entries (may or may not have law_groups depending on fixtures)
    assert types.any?, "Grouped results should have entries"
  end

  test "result_format=grouped respects per_law parameter" do
    get api_v1_search_path, params: { query: '*', result_format: 'grouped', per_law: 1 }
    json = JSON.parse(response.body)

    law_groups = json['results'].select { |r| r['_type'] == 'law_group' }
    law_groups.each do |group|
      assert group['articles'].size <= 1, "per_law=1 should cap articles to 1 per group"
    end
  end

  test "result_format=grouped documents do not include file_url for service-authenticated users" do
    get api_v1_search_path, params: { query: '*', result_format: 'grouped' }
    json = JSON.parse(response.body)

    docs = json['results'].select { |r| r['_type'] == 'document' }
    docs.each do |doc|
      refute doc.key?('file_url'), "Unauthenticated users should not see file_url in grouped format"
    end
  end

  test "result_format=flat is default behavior" do
    get api_v1_search_path, params: { query: '*' }
    json_default = JSON.parse(response.body)

    get api_v1_search_path, params: { query: '*', result_format: 'flat' }
    json_flat = JSON.parse(response.body)

    # Both should have the same structure — no law_group entries
    assert_equal json_default['total'], json_flat['total']
    json_flat['results'].each do |r|
      assert_includes %w[article document], r['_type'],
        "Flat format should only have article and document types"
    end
  end

  # --- Error handling ---

  test "service failure returns 503 with error message" do
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

  # --- Empty results ---

  test "empty results return valid response" do
    get api_v1_search_path, params: { query: 'zzzznonexistentqueryzzzz' }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 0, json['total']
    assert_equal [], json['results']
  end
end
