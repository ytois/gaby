module Gaby
  class Report
    # 複数ではなく単一のクエリずつ投げる
    def initialize(params)
      params = params.map{ |k, v| [k.to_sym, v] }.to_h
      @query = Gaby::Query.new(params)
    end

    # def validation
    #   raise ArgumentError, "view_id and metrics are mandatory."  unless (@query.view_id & @query.metrics)
    # end

    def model
      @query
    end

    def model=(params)
      @query.attributes = params
    end

    def query=(query)
      @query = query
    end

    def get(options = {})
      get_raw(options)
    end

    def get_all(options = {})
      @query.index = 1..10000
      data = get(options)
      while data.next_page_token
        @query = data.next_page_query
        data.merge(get(options))
      end
      data
    end

    # private

    def get_raw(options = {})
      query = Marshal.load(Marshal.dump(@query))
      query.parameters = options
      Gaby::Client.get(query)
    end
  end
end
