module MongoCore
  class Scope
    attr_accessor :query

    def initialize(query)
      @query = (@query || {}).merge(query)
    end

  end
end
