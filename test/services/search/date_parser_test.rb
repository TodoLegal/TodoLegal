require 'test_helper'

class Search::DateParserTest < ActiveSupport::TestCase
  # --- Spanish natural language dates ---

  test "parses full Spanish date: 20 de mayo del 2024" do
    result = Search::DateParser.parse("20 de mayo del 2024")
    assert_equal "2024-05-20", result[:date]
    assert_equal :spanish, result[:format]
  end

  test "parses Spanish date with 'de' instead of 'del': 15 de junio de 2023" do
    result = Search::DateParser.parse("15 de junio de 2023")
    assert_equal "2023-06-15", result[:date]
    assert_equal :spanish, result[:format]
  end

  test "parses Spanish date without year (defaults to current year)" do
    result = Search::DateParser.parse("20 de mayo")
    assert_equal "#{Date.today.year}-05-20", result[:date]
    assert_equal :spanish, result[:format]
  end

  test "parses single-digit day: 3 de enero del 2022" do
    result = Search::DateParser.parse("3 de enero del 2022")
    assert_equal "2022-01-03", result[:date]
  end

  test "parses all 12 Spanish months" do
    months = {
      'enero' => '01', 'febrero' => '02', 'marzo' => '03', 'abril' => '04',
      'mayo' => '05', 'junio' => '06', 'julio' => '07', 'agosto' => '08',
      'septiembre' => '09', 'octubre' => '10', 'noviembre' => '11', 'diciembre' => '12'
    }

    months.each do |name, number|
      result = Search::DateParser.parse("15 de #{name} del 2024")
      assert_equal "2024-#{number}-15", result[:date], "Failed to parse month: #{name}"
    end
  end

  test "Spanish parser is case-insensitive" do
    result = Search::DateParser.parse("20 de Mayo del 2024")
    assert_equal "2024-05-20", result[:date]
  end

  # --- Slash format ---

  test "parses slash date: 15/03/2023" do
    result = Search::DateParser.parse("15/03/2023")
    assert_equal "2023-03-15", result[:date]
    assert_equal :slash, result[:format]
  end

  test "parses slash date: 01/12/2020" do
    result = Search::DateParser.parse("01/12/2020")
    assert_equal "2020-12-01", result[:date]
    assert_equal :slash, result[:format]
  end

  # --- Dash format ---

  test "parses dash date: 15-03-2023" do
    result = Search::DateParser.parse("15-03-2023")
    assert_equal "2023-03-15", result[:date]
    assert_equal :dash, result[:format]
  end

  test "parses dash date: 28-02-2022" do
    result = Search::DateParser.parse("28-02-2022")
    assert_equal "2022-02-28", result[:date]
    assert_equal :dash, result[:format]
  end

  # --- Non-date strings return nil ---

  test "returns nil for regular search query" do
    assert_nil Search::DateParser.parse("constitución")
  end

  test "returns nil for law name" do
    assert_nil Search::DateParser.parse("código penal")
  end

  test "returns nil for blank string" do
    assert_nil Search::DateParser.parse("")
  end

  test "returns nil for nil input" do
    assert_nil Search::DateParser.parse(nil)
  end

  test "returns nil for unknown month name" do
    assert_nil Search::DateParser.parse("20 de mesfalso del 2024")
  end

  # --- Edge cases ---

  test "returns nil for invalid date: 31 de febrero del 2024" do
    assert_nil Search::DateParser.parse("31 de febrero del 2024")
  end

  test "returns nil for invalid slash date: 32/13/2024" do
    assert_nil Search::DateParser.parse("32/13/2024")
  end

  test "strips surrounding whitespace" do
    result = Search::DateParser.parse("  15/03/2023  ")
    assert_equal "2023-03-15", result[:date]
  end

  test "strips quotes from query" do
    result = Search::DateParser.parse('"20 de mayo del 2024"')
    assert_equal "2024-05-20", result[:date]
  end
end
