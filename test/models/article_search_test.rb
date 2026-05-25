require 'test_helper'

class ArticleSearchTest < ActiveSupport::TestCase
  parallelize(workers: 1) # ES reindex in setup is not safe with parallel workers — each worker deletes the previous index

  setup do
    Article.reindex
  end

  # --- Keyword search on body ---

  test "find article by body keyword: soberanía" do
    results = Article.search("soberanía")
    assert results.any?, "Should find articles containing 'soberanía'"
    assert results.any? { |r| r.body.include?("soberanía") },
      "Result body should contain the search term"
  end

  test "find article by body keyword: legalidad" do
    results = Article.search("legalidad")
    assert results.any?, "Should find Código Penal Art. 1 (PRINCIPIO DE LEGALIDAD)"
  end

  test "find article by legal concept: tarjetas de crédito" do
    results = Article.search("tarjetas de crédito")
    assert results.any?, "Should find articles about tarjetas de crédito"
  end

  test "find article by body keyword: concesionarios" do
    results = Article.search("concesionarios")
    assert results.any?, "Should find Ley de Representantes Art. 4 about concesionarios"
  end

  # --- Denormalized law name search ---

  test "search by law name returns articles from that law" do
    results = Article.search("Constitución")
    law_ids = results.map(&:law_id).uniq
    constitucion = laws(:one)
    assert_includes law_ids, constitucion.id,
      "Searching 'Constitución' should return articles from that law via denormalized law_name"
  end

  # --- HTML/Markdown sanitization ---

  test "search_data strips HTML tags from body" do
    article = articles(:codigo_penal_art3)
    data = article.search_data
    refute_match(/<p>/, data[:body], "search_data body should not contain <p> tags")
    refute_match(/<em>/, data[:body], "search_data body should not contain <em> tags")
    refute_match(/<\/p>/, data[:body], "search_data body should not contain </p> tags")
  end

  test "search_data strips markdown bold from body" do
    article = articles(:tarjetas_art1)
    data = article.search_data
    refute_match(/\*\*/, data[:body], "search_data body should not contain markdown ** syntax")
  end

  test "sanitized body preserves meaningful text content" do
    article = articles(:codigo_penal_art3)
    data = article.search_data
    assert_match(/PRINCIPIO DE HUMANIDAD/, data[:body],
      "Sanitized body should preserve the meaningful text")
    assert_match(/dignidad humana/, data[:body],
      "Sanitized body should preserve text that was inside HTML tags")
  end

  # --- Denormalized law fields ---

  test "search_data includes all denormalized law fields" do
    article = articles(:one)
    data = article.search_data
    assert_equal "Constitución de la República", data[:law_name]
    assert_equal "131-1982", data[:law_creation_number]
    assert_equal "vigente", data[:law_status]
    assert_kind_of Array, data[:law_tag_names]
  end

  test "search_data law_tag_names contains real tags" do
    article = articles(:codigo_penal_art1)
    data = article.search_data
    assert data[:law_tag_names].any?, "Código Penal articles should have denormalized tag names"
  end

  # --- Nonexistent query ---

  test "search for nonexistent term returns no results" do
    results = Article.search("blockchain criptomoneda NFT")
    assert_empty results, "Search for unrelated terms should return no results"
  end
end
