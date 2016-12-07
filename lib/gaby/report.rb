module Gaby
  class Report
    def initialize(params)
      params = params.map{ |k, v| [k.to_sym, v] }.to_h
      @query = Gaby::Query.new({
        view_id:    params[:view_id],
        dimensions: params[:dimensions],
        metrics:    params[:metrics],
        dates:      params[:dates],
        filters:    params[:filters],
        segments:   params[:segments]
      })
    end

    def validation
      raise ArgumentError, "view_id and metrics are mandatory."  unless (@query.view_id & @query.metrics)
    end

    def model
      @query
    end

    def model=(params)
      @query.attributes = params
    end

    def get(options = {})
      query = Marshal.load(Marshal.dump(@query))
      query.parameters = options

      res = Gaby::Client.excute(query)
      # Gaby::GaData.new(res, query)
      res
    end

    def get_all(options = {})
    end
  end
end
