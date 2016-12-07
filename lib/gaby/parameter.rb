require 'date'

module Gaby
  module Parameter
    class Base
      def inspect
        {@name => @param}.to_s
      end
    end

    class ViewId < Base
      def initialize(id)
        @name = :view_id
        @param = id
      end

      def to_query
        {viewId: @param.to_s}
      end
    end

    class Dimensions < Base
      def initialize(*args)
        @name = :dimensions
        @param = args.flatten.uniq.compact
      end

      def <<(*args)
        @params = [@params, args].flatten.uniq.compact
      end

      def to_query
        {dimensions: @param.map{ |p| {name: "ga:#{p}"} }}
      end
    end

    class Metrics < Base
      def initialize(*args)
        @name = :metrics
        @param = args.flatten.uniq.compact
      end

      def <<(*args)
        @params = [@params, args].flatten.uniq.compact
      end

      def to_query
        {metrics: @param.map{ |p| {expression: "ga:#{p}"} }}
      end
    end

    class Dates < Base
      # TODO: 複数の日付に対応
      def initialize(date)
        @name = :dates
        set_date(date)
      end

      def to_query
        {
          dateRanges: [{
            startDate: @start_date,
            endDate: @end_date,
          }]
        }
      end

      private
      def set_date(value)
        case value
        when Range
          @start_date = parse_date(value.first)
          @end_date = parse_date(value.last)
        else
          @start_date = parse_date(value)
          @end_date = parse_date(value)
        end
        @param = @start_date..@end_date
      end

      def parse_date(value)
        date = nil
        case value
        when Date
          date = value
        when Time
          date = value.to_date
        when String
          if value.match(/\d{4}-\d{2}-\d{2}/)
            date = value.to_date
          elsif value.to_sym == :today
            date = Date.current
          elsif value.to_sym == :yesterday
            date = Date.yesterday
          end
        end
        if date.nil?
          raise ArgumentError
        else
          date
        end
      end
    end

    class PageSize
    end

    class OrderBy
    end

    class Filter
      def initialize(*filters)
        @name = :filters
      end

      def add_filter(type, name, expression)
      end

      def to_query
        query = {
          dimensionFilterClauses: []
        }
        query
      end
    end

    class FilterV3
      def initialize(filter)
        @name = :filters_v3
        @param = filter
      end

      def to_query
        {filtersExpression: @param}
      end
    end
  end
end

