module Gaby
  class SegmentFilter
    DEFAULT_TARGET = :session

    def initialize(segments, options = {})
      @segment_list = [segments].flatten
      @target       = options[:target] || DEFAULT_TARGET
      @segment_name = options[:name] || "segment_name_#{Random.new.rand(1..1000)}"
    end

    def to_query
      segment_filters = @segment_list.map do |segment|
        segment.to_query
      end
      {
        dynamicSegment: {
          name: @segment_name,
          "#{@target}Segment": {
            segmentFilters: segment_filters,
          }
        }
      }
    end
  end

  module Segment
    class Custom
      def initialize(id)
      end
    end

    class Simple
      DEFAULT_OPERATOR = "REGEXP"
      DIMENSION_FIELD = [:type, :name, :not, :operator, :expressions, :case_sensitive, :min_comparison_value, :max_comparison_value].freeze
      METRICS_FIELD = [:type, :name, :not, :operator, :scope, :comparison_value, :max_comparison_value].freeze

      def initialize(*conditions)
        @conditions = []
        conditions.each do |cond|
          add_condition(cond)
        end
      end

      def add_condition(condition)
        common = {
          type: condition[:type].to_sym,
          name: condition[:name].to_sym,
          not: condition[:not] || false,
          operator: condition[:operator] || DEFAULT_OPERATOR,
          max_comparison_value: condition[:max_comparison_value],
        # dimensions
          expressions: [condition[:expressions]].flatten.compact.uniq,
          case_sensitive: condition[:case_sensitive] || false,
        # metrics
          scope: condition[:scope],
          comparison_value: condition[:comparison_value],
        }

        @conditions << common.select do |key, value|
          if common[:type] == :dimension
              DIMENSION_FIELD.include?(key) & value
          elsif common[:type] == :metrics
              METRICS_FIELD.include?(key) & value
          else
            raise ArgumentError, "type must be :dimension or :metrics."
          end
        end
      end

      def to_query
        {simpleSegment: {
          orFiltersForSegment: @conditions.map{ |condition| to_filter_clauses(condition) }
          }
        }
      end

      private

      def to_filter_clauses(condition)
        filter_clauses = {
          "#{condition[:type]}Name": "ga:#{condition[:name]}",
          operator: condition[:operator],
        }
        condition.except(:type, :name, :operator).each do |name, value|
          filter_clauses[name] = value
        end

        {
          segmentFilterClauses: [{
            "#{condition[:type]}Filter": filter_clauses
          }]
        }
      end
    end

    class Sequence
    end
  end
end

