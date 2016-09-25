module Gaby
  class Report

    attr_reader :model

    def initialize(params)
      @model = Query.new(params)
    end

    def get(options = {})
      raise "oauthrize error" unless Gaby.authorized?

      query = @model.to_query(options)
      res = Gaby.client.execute(
        api_method: Gaby.api.data.ga.get,
        parameters: query,
      )
      if res.response.status == 200
        JSON.parse res.response.body
      else
        # TODO: エラーハンドリング
        res
      end
    end

    def parse_report
    end

    def get_all(options = {})
    end

    def next
    end
  end
end