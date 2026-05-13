require 'test_helper'

class Search::ResultGrouperTest < ActiveSupport::TestCase
  # Build a minimal HashWrapper-like struct for testing without ES
  def make_source(index:, id:, law_id: nil)
    attrs = { '_index' => index, 'id' => id }
    attrs['law_id'] = law_id if law_id
    Hashie::Mash.new(attrs)
  end

  def article(id:, law_id:)
    make_source(index: 'articles_test_20260507', id: id, law_id: law_id)
  end

  def document(id:)
    make_source(index: 'documents_test_20260507', id: id)
  end

  # --- Grouping ---

  test "groups articles by law_id" do
    results = [
      [article(id: 1, law_id: 10), {}],
      [article(id: 2, law_id: 10), {}],
      [article(id: 3, law_id: 10), {}]
    ]

    grouped = Search::ResultGrouper.call(results)
    assert_equal 1, grouped.size
    assert_equal :law_group, grouped[0][:type]
    assert_equal 10, grouped[0][:law_id]
    assert_equal 3, grouped[0][:articles].size
  end

  test "first-seen positioning preserves ES order" do
    results = [
      [article(id: 1, law_id: 10), { body: "hit1" }],  # score 0.95
      [article(id: 2, law_id: 10), { body: "hit2" }],  # score 0.90 → absorbed into group at pos 0
      [document(id: 100), { name: "doc" }],              # score 0.85 → pos 1
      [article(id: 3, law_id: 20), { body: "hit3" }],   # score 0.80 → new group at pos 2
    ]

    grouped = Search::ResultGrouper.call(results)

    assert_equal 3, grouped.size
    # Position 0: law_group for law 10
    assert_equal :law_group, grouped[0][:type]
    assert_equal 10, grouped[0][:law_id]
    assert_equal 2, grouped[0][:articles].size

    # Position 1: document
    assert_equal :document, grouped[1][:type]
    assert_equal 100, grouped[1][:source].id

    # Position 2: law_group for law 20
    assert_equal :law_group, grouped[2][:type]
    assert_equal 20, grouped[2][:law_id]
    assert_equal 1, grouped[2][:articles].size
  end

  test "documents stay at original position" do
    results = [
      [document(id: 100), {}],
      [document(id: 101), {}],
      [article(id: 1, law_id: 10), {}],
      [document(id: 102), {}]
    ]

    grouped = Search::ResultGrouper.call(results)

    assert_equal 4, grouped.size
    assert_equal :document, grouped[0][:type]
    assert_equal :document, grouped[1][:type]
    assert_equal :law_group, grouped[2][:type]
    assert_equal :document, grouped[3][:type]
  end

  # --- per_law cap ---

  test "per_law caps articles per group" do
    results = (1..5).map { |i| [article(id: i, law_id: 10), {}] }

    grouped = Search::ResultGrouper.call(results, per_law: 3)

    assert_equal 1, grouped.size
    assert_equal 3, grouped[0][:articles].size
    # First 3 articles kept
    assert_equal [1, 2, 3], grouped[0][:articles].map { |s, _| s.id }
  end

  test "per_law defaults to 10" do
    results = (1..12).map { |i| [article(id: i, law_id: 10), {}] }

    grouped = Search::ResultGrouper.call(results)

    assert_equal 1, grouped.size
    assert_equal 10, grouped[0][:articles].size
  end

  test "per_law clamped to MAX_PER_LAW" do
    results = (1..25).map { |i| [article(id: i, law_id: 10), {}] }

    grouped = Search::ResultGrouper.call(results, per_law: 999)

    assert_equal 1, grouped.size
    assert_equal 20, grouped[0][:articles].size
  end

  # --- Edge cases ---

  test "empty input returns empty array" do
    assert_equal [], Search::ResultGrouper.call([])
  end

  test "nil input returns empty array" do
    assert_equal [], Search::ResultGrouper.call(nil)
  end

  test "all documents input returns flat array" do
    results = [
      [document(id: 100), {}],
      [document(id: 101), {}]
    ]

    grouped = Search::ResultGrouper.call(results)

    assert_equal 2, grouped.size
    grouped.each { |entry| assert_equal :document, entry[:type] }
  end

  test "all articles from one law in single group" do
    results = [
      [article(id: 1, law_id: 10), {}],
      [article(id: 2, law_id: 10), {}]
    ]

    grouped = Search::ResultGrouper.call(results)

    assert_equal 1, grouped.size
    assert_equal :law_group, grouped[0][:type]
    assert_equal 2, grouped[0][:articles].size
  end

  test "multiple laws with single article each" do
    results = [
      [article(id: 1, law_id: 10), {}],
      [article(id: 2, law_id: 20), {}],
      [article(id: 3, law_id: 30), {}]
    ]

    grouped = Search::ResultGrouper.call(results)

    assert_equal 3, grouped.size
    grouped.each do |entry|
      assert_equal :law_group, entry[:type]
      assert_equal 1, entry[:articles].size
    end
  end

  test "articles preserve their highlights in groups" do
    hl1 = { body: "highlighted <mark>text</mark>" }
    hl2 = { body: "another <mark>match</mark>" }

    results = [
      [article(id: 1, law_id: 10), hl1],
      [article(id: 2, law_id: 10), hl2]
    ]

    grouped = Search::ResultGrouper.call(results)

    assert_equal hl1, grouped[0][:articles][0][1]
    assert_equal hl2, grouped[0][:articles][1][1]
  end
end
