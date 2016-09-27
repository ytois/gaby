module Gaby
  class Report

    attr_reader :model

    def initialize(params)
      @model = Query.new(params)
    end

    def get(options = {})
      query = @model.to_query(options)
      res = Gaby.excute(query)
      Gaby::GaData.new(res, query)
    end
  end
end
