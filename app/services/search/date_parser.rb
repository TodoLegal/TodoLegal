# frozen_string_literal: true

module Search
  # Parses date strings from user search queries into structured results.
  # Consolidates date parsing logic previously duplicated in:
  #   - DocumentsController#parse_spanish_date_to_iso (search queries)
  #   - DocumentJsonBatchProcessor#parse_date (document import)
  #
  # Supported formats:
  #   - Spanish natural language: "20 de mayo del 2024", "15 de junio de 2023"
  #   - Slash format: "15/03/2023" (dd/mm/yyyy)
  #   - Dash format: "15-03-2023" (dd-mm-yyyy)
  #   - Non-date strings return nil
  #
  # Usage:
  #   result = Search::DateParser.parse("20 de mayo del 2024")
  #   # => { date: "2024-05-20", format: :spanish }
  #
  #   result = Search::DateParser.parse("15/03/2023")
  #   # => { date: "2023-03-15", format: :slash }
  #
  #   result = Search::DateParser.parse("constitución")
  #   # => nil
  class DateParser
    SPANISH_MONTHS = {
      'enero' => 1, 'febrero' => 2, 'marzo' => 3, 'abril' => 4,
      'mayo' => 5, 'junio' => 6, 'julio' => 7, 'agosto' => 8,
      'septiembre' => 9, 'octubre' => 10, 'noviembre' => 11, 'diciembre' => 12
    }.freeze

    # Matches: "20 de mayo", "20 de mayo del 2024", "20 de mayo de 2024"
    SPANISH_DATE_REGEX = /(\d{1,2})\s+de\s+(\w+)(?:\s+del?\s+(\d{4}))?/i

    SLASH_DATE_REGEX = /\A(\d{2})\/(\d{2})\/(\d{4})\z/
    DASH_DATE_REGEX  = /\A(\d{2})-(\d{2})-(\d{4})\z/

    def self.parse(query)
      return nil if query.blank?

      cleaned = query.strip.gsub(/"/, '')

      parse_spanish(cleaned) || parse_slash(cleaned) || parse_dash(cleaned)
    end

    class << self
      private

      def parse_spanish(query)
        match = query.match(SPANISH_DATE_REGEX)
        return nil unless match

        day = match[1].to_i
        month = SPANISH_MONTHS[match[2].downcase]
        return nil unless month

        year = match[3]&.to_i || Date.today.year

        date = Date.new(year, month, day)
        { date: date.strftime('%Y-%m-%d'), format: :spanish }
      rescue ArgumentError
        nil
      end

      def parse_slash(query)
        match = query.match(SLASH_DATE_REGEX)
        return nil unless match

        date = Date.new(match[3].to_i, match[2].to_i, match[1].to_i)
        { date: date.strftime('%Y-%m-%d'), format: :slash }
      rescue ArgumentError
        nil
      end

      def parse_dash(query)
        match = query.match(DASH_DATE_REGEX)
        return nil unless match

        date = Date.new(match[3].to_i, match[2].to_i, match[1].to_i)
        { date: date.strftime('%Y-%m-%d'), format: :dash }
      rescue ArgumentError
        nil
      end
    end
  end
end
