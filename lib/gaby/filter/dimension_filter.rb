module Gaby
  class DimensionFilter
    def initialize(options = {})
      @operator = 'REGEXP'
      @case_sensitive = false
      case_sensitive(options[:case_sensitive])
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

    def to_query
      query = {
        dimensionName: "ga:#{@name}",
        operator: @operator,
        expressions: [@expressions].flatten,
        caseSensitive: @case_sensitive,
      }
      query[:not] = @not if @not
      query
    end
  end
end
