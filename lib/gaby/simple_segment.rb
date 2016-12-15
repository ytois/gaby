require 'gaby/simple_segment/simple_segment_dimension'
require 'gaby/simple_segment/simple_segment_metric'

module Gaby
  module SimpleSegment
    def self.dimension
      Dimension.new
    end

    def self.metric
      Metric.new
    end
  end
end
