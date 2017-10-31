module Mongocore
  class Access

    # # # # # # # #
    # The Access class is responsible for checking if an attribute
    # can be read or written. It uses 7 access levels and the
    # read and write attributes in the schema yml file for the model.
    #
    # If your current access level is above the key level, then you
    # can read or write, if not you get nil. This is very useful for APIs
    # where f.ex. you want to show the email to logged in users, but not to all.
    #

    # Access levels (7)
    AL = [:all, :user, :owner, :dev, :admin, :super, :app]

    # Holds the keys from the model schema
    attr_accessor :keys

    # The access control class
    def initialize(schema)
      @keys = schema.keys
    end

    # Key readable?
    def read?(key)
      ok?(keys[key][:read] || :all) rescue false
    end

    # Key writable?
    def write?(key)
      ok?(keys[key][:write] || :all) rescue false
    end

    # Ok?
    def ok?(level)
      !Mongocore.access || self.class.get.nil? || AL.index(level.to_sym) <= AL.index(self.class.get || :app)
    end


    ###########################
    # Class methods
    #

    # Reset the access level
    def self.reset
      RequestStore.store[:access] = nil
    end

    # Get the current access level
    def self.get
      RequestStore.store[:access]
    end

    # Set the current access level
    def self.set(level = nil)
      (level.nil? || set?(level)) ? RequestStore.store[:access] = level : get
    end

    # Set?
    def self.set?(level)
      AL.index(level) >= AL.index(get || :all)
    end

    # Access block
    # Run with Mongocore::Access.role(:user){ # Do something as :user}
    def self.role(level, &block)
      set(level); yield.tap{ set(nil)}
    end

  end
end
