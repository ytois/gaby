module Gaby
  class Query
    PARAMS = [:view_id, :dimensions, :metrics].freeze

    def initialize(paramas)
      paramas.each do |k, v|
        if PARAMS.include?(k.to_sym)
          send(k, v) 
        else
          warn "unknown parameter - #{k}."
        end
      end
    end

    def view_id(id)
      @view_id ||= Gaby.default_view_id
      @view_id = id
    end

    def dimensions(*args)
      @dimensions ||= Parameter.new(:dimensions)
      @dimensions << args
    end

    def metrics(*args)
      @metrics ||= Parameter.new(:metrics)
      @metrics << args
    end

    def date(value)
      if value.is_a?(Range)
        start_date parse_date(value.first)
        end_date parse_date(value.last)
      else
        v = parse_date(value)
        start_date(v)
        end_date(v)
      end
    end

    def to_query(options = {})
      # options - :date, :index
      query = {
        ids: "ga:#{@view_id}",
        start_date:  (Date.today - 31).strfime("%F"),
        end_date:    (Date.today - 1).strfime("%F"),
        start_index: 1,
        max_results: 1000
      }

      query[:view_id] = options[:view_id] if options[:view_id]

      if date = options[:date]
        if date.is_a?(Range)
          query[:start_date] = parse_date(date.first)
          query[:end_date]   = parse_date(date.last)
        else
          date = parse_date(date)
          query[:start_date] = date
          query[:end_date] = date
        end
      end

      if options[:index]
        query[:start_index] = options[:index].first 
        query[:max_results] = options[:index].last
      end

      [dimensions, metrics, filters].each do |p|
        query.merge!(p.to_params)
      end
      query.map{ |k, v| [k.to_s.sub("_", "-"), v] }.to_h
    end

    private

    def parse_date(value)
      if value.is_a?(Date) || value.is_a?(Time)
        value.to_date.strftime("%F")
      elsif value.is_a?(String) && value.match(/today|yesterday|\d+DayAgo|\d{4}-d{2}-d{2}/)
        value
      else
        raise ArgumentError
      end
    end
  end

  class Parameter

    attr_reader :elements

    def initialize(name)
      @name = name
      @elements = []
    end

    def name
      @name.to_sym
    end

    def set(element)
      (@elements = [element].flatten).compact!
      self
    end

    def add(element)
      (@elements += [element].flatten).compact!
      self
    end

    def <<(element)
      add(element)
    end

    def to_params
      value = self.elements.map { |param| "ga:#{param}" }.join(',')
      value.empty? ? {} : {self.name => value}
    end
  end
end