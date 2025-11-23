# frozen_string_literal: true
require 'test_helper'

class LawsManifestBuilderTest < ActiveSupport::TestCase
  # Basic sanity test for manifest structure & ranges.
  def setup
    @law = Law.create!(name: 'Ley de Prueba', creation_number: 'X1', status: 'vigente')
    # Minimal hierarchy
    @book = @law.books.create!(position: 1, number: 'I', name: 'Libro I')
    @title = @law.titles.create!(position: 10, number: 'II', name: 'Título II')
    @chapter = @law.chapters.create!(position: 20, number: 'III', name: 'Capítulo III')
    @section = @law.sections.create!(position: 30, number: '1', name: 'Sección 1')
    @subsection = @law.subsections.create!(position: 40, number: 'a', name: 'Subsección a')
    # Articles with positions ensuring they fall under successive containers
    (1..5).each do |i|
      @law.articles.create!(number: i.to_s, body: "Body #{i}", position: i * 10)
    end
  end

  test 'build returns expected top-level keys' do
    manifest = Laws::ManifestBuilder.build(@law)
    assert_equal @law.id, manifest[:law_id]
    assert manifest[:version].is_a?(String)
    assert manifest[:chunking][:total_articles] == 5
    assert manifest[:structure].is_a?(Array)
    assert manifest[:articles].size == 5
  end

  test 'article index includes global_index and chunk_page' do
    manifest = Laws::ManifestBuilder.build(@law, chunk_size: 2)
    first = manifest[:articles].first
    assert_equal 0, first[:global_index]
    assert_equal 1, first[:chunk_page]
    third = manifest[:articles][2]
    assert_equal 2, third[:global_index]
    assert_equal 2, third[:chunk_page] # since chunk_size=2 => indices 0-1 page1, 2-3 page2
  end

  test 'structure tree nesting order' do
    manifest = Laws::ManifestBuilder.build(@law)
    book_node = manifest[:structure].first
    assert_equal 'book', book_node[:type]
    title_node = book_node[:children].first
    assert_equal 'title', title_node[:type]
    chapter_node = title_node[:children].first
    assert_equal 'chapter', chapter_node[:type]
    section_node = chapter_node[:children].first
    assert_equal 'section', section_node[:type]
    subsection_node = section_node[:children].first
    assert_equal 'subsection', subsection_node[:type]
  end

  test 'ranges contain first and last article indices or nil when empty' do
    manifest = Laws::ManifestBuilder.build(@law)
    book_node = manifest[:structure].first
    range = book_node[:range]
    assert range[:first_article_index].is_a?(Integer)
    assert range[:last_article_index].is_a?(Integer)
  end
end
