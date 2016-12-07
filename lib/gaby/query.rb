module Gaby
  class Query
    PARAMS = [:view_id, :dimensions, :metrics, :dates, :page_size, :order_by, :filters, :filters_v3, :segments].freeze
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
        # index: index,
        # filters: filters,
        # sort: sort,
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

    def page_size=(size = nil)
      @page_size = size || @page_size
    end

    def filters=(*args)
    end

    def order_by=(dimension = nil, order = :asc)
    end

    def segments=(*args)
      @segments = [args].flatten
    end

    def to_query
      query = {}
      PARAMS.each do |p|
        if p == :segments
          segment_filter = send(p).map do |segment|
            segment.to_query
          end
          query.merge!(segments: segment_filter) if segment_filter.present?
        else
          query.merge!(send(p).to_query) unless send(p).nil?
        end
      end
      query
    end

    private

    def default_parameters
      dates = 31.day.ago.to_date..Date.yesterday
    end

    def set_parameters (params)
      params.each do |name, value|
        if PARAMS.include?(name.to_sym)
          send("#{name}=", value)
        else
          warn "unknown parameter - #{k}."
        end
      end
      self
    end
  end
end
