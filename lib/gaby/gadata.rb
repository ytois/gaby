module Gaby
  class GaData
    attr_reader :query, :column_header, :total_results, :contains_sampled_data, :self_link, :total_for_all_results, :row

    def initialize(response_body, query)
      @query = query
      @column_header = response_body["columnHeaders"]
      @total_results = response_body["totalResults"]
      @contains_sampled_data = response_body["containsSampledData"]
      @self_link = response_body["selfLink"]
      @total_for_all_results = parse_row(response_body["totalsForAllResults"].values)
      @rows = parse_rows(response_body["rows"])
    end

    # TODO: columns.col-nameで特定列のarrayを返せるように
    def columns
      @column_header.map do |c|
        c["name"].delete("ga:").to_sym
      end
    end

    # 次の範囲を取得
    def next(max_results = nil)
      raise ArgumentError if max_results.to_i > 10000
      return unless @rows # 初回取得前ならnilで返す

      # 次の範囲を詰め直す
      query = @query.dup
      query["start-index"] += query["max-results"]
      query["max-results"] = max_results if max_results # 引数があれば取得範囲を変更

      # 取得して初期化
      res = Gaby.excute(query)
      return if res['rows'].nil? || res['rows'] == []  # 取得結果が空ならnilで返す
      initialize(res, query)
      @rows
    end

    # TODO: あとで実装
    def page
    end

    # 全件取得
    def all
      unless @query["start-index"] == 1
        # 取得済み範囲が1~で無い場合はリセットして再取得
        query = @query.dup
        query["start-index"] = 1
        query["max-results"] = 10000

        res = Gaby.excute(query)
        initialize(res, query)
      end
      rows = @rows.dup

      # nextが空になるまでループ
      begin
        res = self.next(10000)
        rows.concat(res) if res
      end while res

      # 返り値は全件だが、実行後の@rowsは最後の取得範囲になる
      rows
    end

    private

    def parse_rows(rows)
      rows.map do |row|
        parse_row(row)
      end
    end

    def parse_row(row)
      row.map.with_index do |col, i|
        case @column_header[i]["dataType"]
        when "STRING"
          if @column_header[i]["name"] == "ga:date"
            Date.parse(col)
          else
            col
          end
        when "INTEGER"
          col.to_i
        when "TIME"
          parse_time(col)
        else
          col
        end
      end
    end

    def parse_time(sec)
      tmp = sec.to_f / 86400
      Time.new(1970, 1,1,0) + (sec.to_f - tmp)
    end
  end
end
