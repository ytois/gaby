module Gaby
  class MetricFilter
    def initialize(options = {})
    end

    def where(formula)
      tmp_name, tmp_numeric = formula.split(/[<>=]+/)
      if tmp_operator = formula.match(/[<>=]+/)
        tmp_operator = tmp_operator.to_s
      end
      @name = tmp_name.sub(/ +/, '').to_sym
      @comparison_value = tmp_numeric.sub(/ +/, '')
      case tmp_operator
      when "="
        @operator = 'EQUAL'
      when ">"
        @operator = 'GREATER_THAN'
      when "<"
        @operator = 'LESS_THAN'
      else
        raise ArgumentError, "unknown formula."
      end
      self
    end

    def not
      @not = true
      self
    end

    def is_missing(name)
      @name = name
      @operator = 'IS_MISSING'
      self
    end

    def to_query
      query = {
        metricName: "ga:#{@name}",
        operator: @operator,
        comparisonValue: @comparison_value.to_s,
      }
      query[:not] = @not if @not
      query
    end
  end
end
