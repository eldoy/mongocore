module Mongocore
  class Access

    # # # # # # # #
    # The Access class is responsible for checking if an attribute
    # can be read or written. It uses 6 access levels and the
    # read and write attributes in the schema yml file for the model.
    #
    # If your current access level is above the key level, then you
    # can read or write, if you get nil. This is very useful for APIs
    # where f.ex. you want to show the email to logged in users, but not to all.
    #

    # Access levels (6)
    AL = [:all, :user, :dev, :admin, :super, :app]

    # @doc is a Mongocore::Document object
    # @keys are the keys from the model schema
    attr_accessor :keys

    # The access control class
    def initialize(model)
      @keys = model.keys
    end

    # Set the current access level
    def set(level = nil)
      set?(level) ? RequestStore.store[:access] = level : get
    end

    # Get the current access level
    def get
      RequestStore.store[:access]
    end

    # Reset the access level
    def reset
      RequestStore.store[:access] = nil
    end

    # Key readable?
    def read?(key)
      ok?(keys[key][:read]) rescue false
    end

    # Key writable?
    def write?(key)
      ok?(keys[key][:write]) rescue false
    end

    private

    # Set?
    def set?(level)
      AL.index(level) > AL.index(get || :all)
    end

    # Ok?
    def ok?(level)
      AL.index(level.to_sym) <= AL.index(get || :app)
    end

  end
end
