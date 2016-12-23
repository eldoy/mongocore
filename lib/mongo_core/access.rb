module MongoCore
  class Access

    # Access levels (6)
    AL = [:all, :user, :dev, :admin, :super, :app]

    # @query is a MongoCore::Query object
    # @keys are the keys from the model schema
    attr_accessor :query, :keys

    # The access control class
    def initialize(q)
      @query = q
      @keys = q.class.keys
      # puts @query.inspect
      # puts @keys.inspect
    end

    # Set the current access level
    def set(level = nil)
      level = level.to_sym if level
      level = :all unless AL.include?(level)
      cur = get
      cur = (RequestStore.store[:access] = level.to_sym) if !cur or AL.index(level) > AL.index(cur)
      cur
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
      # begin

      # rescue
      #   puts key
      #   exit
      # end
    end

    private

    # Check if level has access
    def check(level)
      # Just give full access if access level not set
      cur = get || :app
      return true if cur == :app
      # Check if the intended level has access
      level = level.to_sym
      AL.index(level) <= AL.index(cur)
    end

  end
end
