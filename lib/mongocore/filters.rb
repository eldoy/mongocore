module Mongocore
  class Filters

    # # # # # # # #
    # The Filters class is responsible for the before, after and validate filters.
    #

    # Accessors
    attr_accessor :klass, :before, :after, :validate

    # Init
    def initialize(klass)
      # The before filters
      @before = Hash.new{|h, k| h[k] = []}

      # The after filters
      @after = Hash.new{|h, k| h[k] = []}

      # The validators
      @validate = []
    end

  end
end