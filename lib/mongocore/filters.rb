module Mongocore
  class Filters

    # # # # # # # #
    # The Filters class is responsible for the before, after and validate filters.
    #

    # Accessors
    attr_accessor :klass, :before, :after, :validate

    # Init
    def initialize(klass)
      # Save model class
      @klass = klass

      # The before filters
      @before = Hash.new{|h, k| h[k] = []}

      # The after filters
      @after = Hash.new{|h, k| h[k] = []}

      # The validators
      @validate = []
    end

    # Valid?
    def valid?(m)
      @validate.each{|k| call(k, m)}; m.errors.empty?
    end

    # Available filters are :save, :update, :delete
    def run(m, f, key = nil)
      send(f)[key].each{|k| call(k, m)}
    end

    # Execute a proc or a method
    def call(k, m)
      k.is_a?(Proc) ? m.instance_eval(&k) : m.send(k)
    end

  end
end
