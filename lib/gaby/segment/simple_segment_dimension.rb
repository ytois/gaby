module Gaby
  module SimpleSegment
    class Dimension
      def initialize
        @type = :dimension
        @case_sensitive = false
        @and_clauses = []
        @or_clauses = []
      end

      def where(value)
        case value
        when Hash
          @name = value.first[0].to_sym
          @expressions = value.first[1]
          case @expressions
          when String
            @operator = 'EXACT'
          when Array
            @operator = 'IN_LIST'
          when Regexp
            @operator = 'REGEXP'
            @expressions = value.first[1].source
          when Range
            @operator = 'NUMERIC_BETWEEN'
            @min_comparison_value = value.first
            @max_comparison_value = value.last
          else
            raise ArgumentError
          end
        when String
          numeric(value)
        end
        self
      end

      def numeric(formula)
        tmp_name, tmp_numeric = formula.split(/[<>=]+/)
        if tmp_operator = formula.match(/[<>=]+/)
          tmp_operator = tmp_operator.to_s
        end
        @name = tmp_name.sub(/ +/, '').to_sym
        @expressions = tmp_numeric.sub(/ +/, '')
        case tmp_operator
        when "="
          @operator = 'NUMERIC_EQUAL'
        when ">"
          @operator = 'NUMERIC_GREATER_THAN'
        when "<"
          @operator = 'NUMERIC_LESS_THAN'
        else
          raise ArgumentError, "unknown formula."
        end
        self
      end

      def not
        @not = true
        self
      end

      def case_sensitive(bool)
        @case_sensitive = !!bool
        self
      end

      def or(segment_filter)
        @or_clauses << segment_filter
        self
      end

      def and(segment_filter)
        @and_clauses << segment_filter
        self
      end

      def to_query
        query = {
          simpleSegment: to_and_clauses
        }
      end

      def to_filter
        query = {
          dimensionName: "ga:#{@name}",
          operator: @operator,
          expressions: [@expressions].flatten,
          caseSensitive: @case_sensitive,
        }
        query[:minComparisonValue] = @min_comparison_value if @min_comparison_value
        query[:maxComparisonValue] = @max_comparison_value if @max_comparison_value
        query[:not] = @not if @not
        {dimensionFilter: query}
      end

      def to_and_clauses
        query = {orFiltersForSegment: [to_or_clauses, @and_clauses.map(&:to_or_clauses)].flatten}
      end

      def to_or_clauses
        query = {segmentFilterClauses: [to_filter, @or_clauses.map(&:to_filter)].flatten}
      end
    end
  end
end
