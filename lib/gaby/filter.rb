module Gaby
  class Filter
    def initialize(*filters)
      @name = :filters
      @param = filters
      @dimension_operator = :and
      @metric_operator = :and
    end

    def self.dimension
      Gaby::DimensionFilter.new
    end

    def self.metric
      Gaby::MetricFilter.new
    end

    def <<(filter)
      @param << filter
    end

    def operator(hash)
      @dimension_operator = hash[:dimension]
      @metric_operator = hash[:metric]
    end

    def to_query
      to_dimension_query.merge(to_metric_query)
    end

    def dimension_filters
      @param.select do |filter|
        filter.is_a?(Gaby::DimensionFilter)
      end
    end

    def metric_filters
      @param.select do |filter|
        filter.is_a?(Gaby::MetricFilter)
      end
    end

    private

    def conversion(value)
      operator = {
        and: 'AND',
        or: 'OR',
        AND: 'AND',
        OR: 'OR'
      }[value]
      operator.nil? ? 'AND' : operator
    end

    def to_dimension_query
      return {} unless dimension_filters.present?
      query = {
        dimensionFilterClauses: [{
          operator: conversion(@dimension_operator),
          filters: dimension_filters.map(&:to_query),
        }],
      }
    end

    def to_metric_query
      return {} unless metric_filters.present?
      query = {
        metricFilterClauses: [{
          operator: conversion(@metric_operator),
          filters: metric_filters.map(&:to_query),
        }],
      }
    end
  end
end
