module Gaby
  class Segment
    def initialize(name)
      @name = name
    end

    def self.simple
      Gaby::SimpleSegment
    end

    def self.custom(id)
      Gaby::CustomSegment.new(id)
    end

    def self.sequence
      Gaby::SeaquenceSegment.new
    end

    def user(*condisions)
      @user = condisions
      self
    end

    def session(*condisions)
      @session = condisions
      self
    end

    def to_query
      query = {
        dynamicSegment: {
          name: @name,
        }
      }

      if @user
        query[:dynamicSegment][:userSegment] = {}
        query[:dynamicSegment][:userSegment][:segmentFilters] = @user.map(&:to_query)
      end

      if @session
        query[:dynamicSegment][:sessionSegment] = {}
        query[:dynamicSegment][:sessionSegment][:segmentFilters] = @session.map(&:to_query)
      end

      query
    end
  end
end
