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

      def <<(dimensions)
        @param = [@param, dimensions].flatten.uniq
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

      def <<(metrics)
        @param = [@param, metrics].flatten.uniq.compact
      end

      def to_query
        {metrics: @param.map{ |p| {expression: "ga:#{p}"} }}
      end
    end

    class Dates < Base
      # TODO: 複数の日付に対応
      def initialize(*dates)
        @name = :dates
        @param = []
        [dates].flatten.each do |date|
          set_date(date)
        end
      end

      def <<(date)
        set_date(date)
      end

      def to_query
        {dateRanges: @param}
      end

      private
      def set_date(value)
        case value
        when Range
          start_date = parse_date(value.first)
          end_date = parse_date(value.last)
        else
          start_date = parse_date(value)
          end_date = parse_date(value)
        end
        @param << {startDate: start_date, endDate: end_date}
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

    class OrderBy < Base
      # def initialize(arg)
      #   if arg.is_a?(Hash)
      #     field_name = arg[:field]
      #     sort_order = arg[:sort_order]
      #     order_type = arg[:order_type]
      #   elsif arg.is_a?(Symbol) || arg.is_a?(String)
      #     field_name = arg
      #   end
      #   @name = :order_by
      #   @param = 
      # end
      #
      # def field_name=(value)
      #   @field_name = value.to_sym
      # end
      #
      # def sort_order=(value = :asc)
      #   'SORT_ORDER_UNSPECIFIED'
      #   'ASCENDING'
      #   'DESCENDING'
      #
      # end
      #
      # def order_type=(value = :default)
      #   'ORDER_TYPE_UNSPECIFIED'
      #   'VALUE'
      #   'DELTA'
      #   'SMART'
      #   'HISTOGRAM_BUCKET'
      #   'DIMENSION_AS_INTEGER'
      # end
      #
      # def to_query
      #   {
      #     fieldName: "ga:#{@field}",
      #     orderType: ,
      #     sortOrder: ,
      #   }
      # end
    end

    class Index < Base
      def initialize(range)
        @name = :index
        set(range)
      end

      def set(range)
        @page_size  = (range.last - range.first) - 1
        @page_token = (range.first - 1)
        update_param
      end

      def update_param
        @param = (@page_token + 1)..(@page_token + @page_size + 2)
      end

      def page_token=(int)
        @page_token = int.to_i
        update_param
      end

      def page_size=(int)
        @page_size = int
        update_param
      end

      def to_query
        query = {pageSize: @page_size}
        query[:pageToken] = @page_token.to_s if @page_token
        query
      end
    end
  end
end

