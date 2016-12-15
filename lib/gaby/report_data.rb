module Gaby
  class ReportsData
    attr_reader :query, :reports

    def initialize(response, query)
      @query = query
      @reports = response["reports"].map do |report|
        parse_report(report)
      end
    end

    def inspect
      reports.to_s
    end

    def [](i)
      @reports[i]
    end

    private

    def parse_report(report)
      ReportData.new(report)
    end
  end

  class ReportData
    DATA_TYPE = {
      "INTEGER": Integer,
      "FLOAT": Float,
      "CURRENCY": "CURRENCY",
      "PERCENT": "PERCENT",
      "TIME": Time,
    }.freeze

    attr_reader :next_page_token, :totals, :row_count, :min, :max, :is_golden, :rows, :dimensions, :columns, :query

    def initialize(report, query)
      @query = query
      @next_page_token = report["nextPageToken"]
      parse_columns(report["columnHeader"])

      @totals = report["data"]["totals"]
      @row_count = report["data"]["rowCount"]
      @min = report["data"]["minimums"]
      @max = report["data"]["maximums"]
      @is_golden = report["data"]["isDataGolden"]
      @rows = parse_rows(report["data"]["rows"])

      define_column_name
    end

    def inspect
      {columns: @columns, rows: head}.to_s
    end

    def metrics
      @metrics.keys
    end

    def head(int = 10)
      @rows.first(int)
    end

    def tail(int = 10)
      @rows.last(int)
    end

    def by_segment(segment_name)
      # セグメントでフィルタ
      return unless @dimensions.include?(:segment)
      dup_data = self.dup
      rows = @rows.select do |row|
        row.dimension.values.include?(segment_name.to_s)
      end
      dup_data.set_rows(rows)
      dup_data
    end

    def filter_dimensions(name, regexp)
      # ディメンションをフィルタ
      dup_data = self.dup
      rows = @rows.select do |row|
        row.dimension[name].match(regexp)
      end
      dup_data.set_rows(rows)
      dup_data
    end

    # TODO: 複数日付の場合絞りこめるように
    def date(int)
    end

    def to_a
      rows.map{ |r| r.to_a }
    end

    def to_csv
    end

    def next_page_query
      @query.page_token = @next_page_token
      @query
    end

    def merge(report)
      return unless report.is_a?(ReportData)
      @rows.concat(report.rows)
      @query = report.query
      @next_page_token = report.next_page_token
      self
    end

    def set_rows(rows)
      @rows = rows
    end

    private

    def parse_columns(columns)
      parse_metrics(columns["metricHeader"])
      parse_dimensions(columns["dimensions"]) if columns["dimensions"]
      @columns = [@dimensions, metrics].flatten
    end

    def parse_metrics(metricHeader)
      @metrics = metricHeader["metricHeaderEntries"].map do |metric|
        name = metric["name"].sub(/^ga:/, '').to_sym
        type = DATA_TYPE[metric["type"].to_sym]
        [name, type]
      end.to_h
    end

    def parse_dimensions(dimensions)
      @dimensions = dimensions.map do |dimension|
        dimension.sub(/^ga:/, '').to_sym
      end
    end

    def parse_rows(rows)
      return [] unless rows
      rows.map do |row|
        ReportRow.new(row, @dimensions, @metrics)
      end
    end

    def define_column_name
      # メトリクス名でアクセスできるように
      @metrics.keys.each do |name|
        self.class.send(:define_method, name) do
          @rows.map(&name)
        end
      end
    end
  end

  class ReportRow
    attr_reader :dimension, :metric

    def initialize(row, dimensions, metrics)
      @dimensions_info = dimensions
      @metrics_info = metrics
      parse_dimension_columns(row["dimensions"]) if row["dimensions"]
      parse_metrics_columns(row["metrics"])

      define_column_name
    end

    def inspect
      {
        dimension: @dimension,
        metric: @metric,
      }.to_s
    end

    def to_a
      # 暫定
      [@dimension.values, @metric].flatten
    end

    private

    def parse_dimension_columns(dimension_columns)
      @dimension = dimension_columns.map.with_index do |dim, i|
        [@dimensions_info[i], dim]
      end.to_h
    end

    def parse_metrics_columns(metrics_columns)
      @metric = metrics_columns.map do |metrics_column|
        metrics_column["values"].map.with_index do |metric, i|
          # name = @metrics_info.to_a[i][0]
          type = @metrics_info.to_a[i][1]
          metric = type == Integer ? metric.to_i : metric
        end
      end
    end

    def define_column_name
      # row.sessionsなどでアクセスできるように
      @metrics_info.keys.each_with_index do |name, i|
        self.class.send(:define_method, name) do
          @metric.map do |m|
            m[i]
          end
        end
      end
    end
  end
end
