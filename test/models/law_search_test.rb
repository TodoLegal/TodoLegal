require 'test_helper'

class LawSearchTest < ActiveSupport::TestCase
  setup do
    Law.reindex
  end

  # --- Keyword search ---

  test "find Constitución by name" do
    results = Law.search("Constitución de la República")
    assert results.any? { |r| r.name.include?("Constitución") },
      "Should find Constitución by full name"
  end

  test "find Código Penal by name" do
    results = Law.search("Código Penal")
    assert results.any? { |r| r.name.include?("Código Penal") },
      "Should find Código Penal by name"
  end

  test "find law by creation number" do
    results = Law.search("130-2017")
    assert results.any? { |r| r.creation_number == "130-2017" },
      "Should find Código Penal by creation number 130-2017"
  end

  test "partial name search returns relevant law" do
    results = Law.search("Tarjetas de Crédito")
    assert results.any? { |r| r.name.include?("Tarjetas") },
      "Should find Ley de Tarjetas de Crédito by partial name"
  end

  # --- Accent-insensitive search ---

  test "accent-insensitive search: Constitución vs Constitucion" do
    with_accents = Law.search("Constitución")
    without_accents = Law.search("Constitucion")
    assert_equal with_accents.map(&:id).sort, without_accents.map(&:id).sort,
      "Search with and without accents should return the same results"
  end

  test "accent-insensitive search: Crédito vs Credito" do
    with_accents = Law.search("Crédito")
    without_accents = Law.search("Credito")
    assert_equal with_accents.map(&:id).sort, without_accents.map(&:id).sort,
      "Search for Crédito/Credito should return same results"
  end

  # --- Status filtering ---

  test "filter by status vigente excludes derogado laws" do
    results = Law.search("*", where: { status: "vigente" })
    assert results.all? { |r| r.status == "vigente" },
      "Status filter 'vigente' should exclude derogado laws"
    refute results.any? { |r| r.name.include?("Representantes") },
      "Ley de Representantes (derogado) should not appear in vigente filter"
  end

  test "filter by status derogado returns only derogado laws" do
    results = Law.search("*", where: { status: "derogado" })
    assert results.all? { |r| r.status == "derogado" },
      "Status filter 'derogado' should only return derogado laws"
    assert results.any? { |r| r.name.include?("Representantes") },
      "Ley de Representantes should appear in derogado filter"
  end

  # --- search_data structure ---

  test "search_data includes all expected fields" do
    law = laws(:one)
    data = law.search_data
    %i[name creation_number status hierarchy tag_names materia_names].each do |key|
      assert data.key?(key), "search_data should include #{key}"
    end
  end

  test "search_data tag_names contains real tag names" do
    law = laws(:one)
    data = law.search_data
    assert_kind_of Array, data[:tag_names]
    assert data[:tag_names].any?, "Constitución should have at least one tag"
  end

  # --- Nonexistent query ---

  test "search for nonexistent law returns no results" do
    results = Law.search("Ley Inexistente de Pruebas Automatizadas")
    assert_empty results, "Search for a nonexistent law name should return no results"
  end
end
