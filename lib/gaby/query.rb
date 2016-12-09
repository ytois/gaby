module Gaby
  class Query
    PARAMS = [:view_id, :dimensions, :metrics, :dates, :index, :order_by, :segments, :filters].freeze
    attr_reader(*PARAMS)

    def initialize(params)
      default_parameters
      set_parameters(params)
    end

    def inspect
      {
        view_id: view_id,
        dimensions: dimensions,
        metrics: metrics,
        dates: dates,
        index: index,
        segments: segments,
        filters: filters,
      }.to_s
    end

    def parameters=(params)
      set_parameters(params)
    end

    def view_id=(id)
      @view_id = Parameter::ViewId.new(id)
    end

    def dimensions=(*args)
      @dimensions = Parameter::Dimensions.new(*args)
    end

    def metrics=(*args)
      @metrics = Parameter::Metrics.new(*args)
    end

    def dates=(date)
      @dates = Parameter::Dates.new(date)
    end

    def index=(range)
      @index = Parameter::Index.new(range)
    end

    def page_token=(int)
      @index ||= Parameter::Index.new(1..1000)
      @index.page_token = int
    end

    def filters=(filter)
      @filters = filter
    end

    def order_by=(dimension = nil, order = :asc)
    end

    def segments=(*args)
      @segments = args.flatten.uniq.compact

      # セグメントを使用する場合はディメンションに:segmentが必須
      if @segments.present?
        if dimensions.present?
          @dimensions << :segment
        else
          self.dimensions = :segment
        end
      end
      @segments
    end

    def to_query
      query = {}
      PARAMS.each do |p|
        if send(p).present?
          if p == :segments
            filter = send(p).map do |f|
              f.to_query
            end
            query.merge!(p => filter)
          else
            query.merge!(send(p).to_query)
          end
        end
      end

      query
    end

    private

    def default_parameters
      self.dates = 31.day.ago.to_date..Date.yesterday
      @dimension_filter_operator = :and
    end

    def set_parameters (params)
      params.each do |name, value|
        if PARAMS.include?(name.to_sym)
          send("#{name}=", value) if value
        else
          warn "unknown parameter - #{name}."
        end
      end
      self
    end
  end
end
