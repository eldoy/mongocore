module MongoCore
  class Access

    # Access levels (6)
    AL = [:all, :user, :dev, :admin, :super, :app]

    # @doc is a MongoCore::Document object
    # @keys are the keys from the model schema
    attr_accessor :doc, :keys

    # The access control class
    def initialize(d)
      @doc = d
      @keys = d.class.keys
    end

    # Set the current access level
    def set(level = nil)
      level = :all unless AL.include?(level = level.to_sym); g = get
      g = (RequestStore.store[:access] = level) if !g or AL.index(level) > AL.index(g)
      g
    end

    # Get the current access level
    def get
      RequestStore.store[:access]
    end

    # Reset the access level
    def reset
      RequestStore.store[:access] = nil
    end

    # Is the current access level sufficient?
    def ok?(level)
      check(level)
    end

    # Key readable?
    def read?(key)
      check(keys[key][:read])
    end

    # Key writable?
    def write?(key)
      check(keys[key][:write])
    end

    private

    # Check if level has access
    def check(level)
      # Just give full access if access level not set
      g = get || :app
      # Check if the intended level has access
      g == :app or AL.index(level.to_sym) <= AL.index(g)
    end

  end
end
