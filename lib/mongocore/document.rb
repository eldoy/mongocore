module Mongocore
  module Document
    extend ActiveSupport::Concern

    # # # # # # # # #
    # The Document module holds data and methods for your models:
    #
    # class Model
    #   include Mongocore::Document
    # end
    #
    # Then after that create a model with m = Model.new
    #
    # The Model class, accessible from Model or m.class, holds the data
    # for your models like the schema and the keys.
    #
    # The model instance, m, lets you do operations on a single model
    # like m.save, m.update, m.delete
    #

    included do

      # Accessors, everything is writable if you need something dynamic.
      class << self
        attr_accessor :schema, :access, :filters
      end

      # Schema
      @schema = Mongocore::Schema.new(self)

      # Access
      @access = Mongocore::Access.new(@schema)

      # Filters
      @filters = Mongocore::Filters.new(self)

      # # # # # # # # # # #
      # Instance variables
      # @db holds the Mongocore.db
      # @errors is used for validates
      # @changes keeps track of object changes
      # @saved indicates whether this is saved or not
      #

      attr_accessor :klass, :db, :schema, :errors, :changes, :saved


      # # # # # # # # # # #
      # The class initializer, called when you write Model.new
      # Pass in attributes you want to set: Model.new(:duration => 60)
      # Defaults are filled in automatically.
      #

      def initialize(a = {})
        a = a.deep_symbolize_keys

        # The _id has the BSON object, create new unless it exists
        a[:_id] ? @saved = true : a[:_id] = BSON::ObjectId.new

        # Short cut for self.class
        @klass = self.class

        # Short cut for db
        @db = Mongocore.db

        # The errors hash
        @errors = Hash.new{|h, k| h[k] = []}

        # The schema
        @schema = @klass.schema

        # Defaults
        @schema.defaults.each{|k, v| write(k, v)}

        # Set the attributes
        a.each{|k, v| write(k, v)}

        # The changes hash
        @changes = Hash.new{|h, k| h[k] = []}
      end


      # # # # # # # # # # # # # # # # # #
      # Instance methods. These can be called with
      # first m = Model.new and then m.method_name
      #

      # Save attributes to db
      def save(o = {})
        # Send :validate => true to validate
        return nil unless valid? if o[:validate]

        # Create a new query
        qq(@klass, {:_id => @_id}).update(attributes).tap{@saved = true; run(:after, :save)}
      end

      # Update document in db
      def update(a = {})
        a.each{|k, v| write(k, v)}
        single.update(a).tap{@saved = true; run(:after, :update)}
      end

      # Delete a document in db
      def delete
        single.delete.tap{run(:after, :delete)}
      end

      # Reload the document from db
      def reload
        single.first
      end

      # Collect the attributes
      def attributes
        a = {}; schema.keys.keys.each{|k| a[k] = read!(k)}; a
      end

      # Set the attributes
      def attributes=(a)
        a.each{|k, v| write!(k, v)}
      end

      # Changed?
      def changed?
        changes.any?
      end

      # Valid?
      def valid?
        @klass.filters.validate.each{|k| call(k)}
        errors.empty?
      end

      # Saved? Persisted?
      def saved?; !!@saved; end

      # Unsaved? New record?
      def unsaved?; !@saved; end

      # Available filters are :save, :update, :delete
      def run(filter, key = nil)
        @klass.filters.send(filter)[key].each{|k| call(k)}
      end

      # Execute a proc or a method
      def call(k)
        k.is_a?(Proc) ? self.instance_eval(&k) : self.send(k)
      end

      # Short cut for setting up a Mongocore::Query object
      def qq(m, q = {}, o = {}, s = {})
        Mongocore::Query.new(m, q, o, {:source => self}.merge(s))
      end

      # Short cut for simple query with cache buster
      def single(s = {:cache => false})
        qq(@klass, {:_id => @_id}, {}, s)
      end

      # Access?
      def access?(mode, key)
        Mongocore.access ? @klass.access.send("#{mode}?", key) : true
      end

      # Get attribute if access
      def read(key)
        access?(:read, key) ? read!(key) : nil
      end

      # Get attribute
      def read!(key)
        instance_variable_get("@#{key}")
      end

      # Set attribute if access
      def write(key, val)
        return nil unless access?(:write, key)
        # Convert to type as in schema yml
        v = convert(key, val)

        # Record change for dirty attributes
        read!(key).tap{|r| @changes[key] = r if v != r} if @changes

        # Write attribute
        write!(key, v)
      end

      # Set attribute
      def write!(key, v)
        instance_variable_set("@#{key}", v)
      end

      # Convert type if val and schema type is set
      def convert(key, val)
        return nil if val.nil?
        type = schema.keys[key][:type].to_sym rescue nil
        return val if type.nil?

        # Convert to the same type as in the schema
        return val.to_i if type == :integer
        return val.to_f if type == :float
        return !!val    if type == :boolean
        if type == :object_id and !val.is_a?(BSON::ObjectId)
          return BSON::ObjectId.from_string(val) rescue nil
        end
        val
      end

      # Dynamically read or write attributes
      def method_missing(name, *arguments, &block)
        # Extract name and write mode
        name =~ /([^=]+)(=)?/

        # Write or read
        if schema.keys.has_key?(key = $1.to_sym)
          return write(key, arguments.first) if $2
          return read(key)
        end

        # Attributes changed?
        return changes.has_key?($1.to_sym) if key =~ /(.+)_changed\?/

        # Attributes was
        return changes[$1.to_sym] if key =~ /(.+)_was/

        # Pass if nothing found
        super
      end

    end


    # # # # # # # # # # # # # # #
    # Class methods
    #

    class_methods do

      # Find, takes an id or a hash
      def find(*args)
        qq(self, *args)
      end

      # Count
      def count(*args)
        find(*args).count
      end

      # First
      def first(*args)
        find(*args).first
      end

      # Last
      def last
        sort(:$natural => -1).first
      end

      # All
      def all(*args)
        find(*args).all
      end

      # Sort
      def sort(o = {})
        find({}, {}, :sort => o)
      end

      # Limit
      def limit(n = 1)
        find({}, {}, :limit => n)
      end

      # Register after and before. Pass a method name as symbol or a block
      # Possible filters are :save, :update, :delete
      def after(*args, &block)
        filters.after[args[0]] << (args[1] || block)
      end

      def before(*args, &block)
        filters.before[args[0]] << (args[1] || block)
      end

      # Register validate. Only takes a block
      def validate(*args, &block)
        filters.validate << (args[0] || block)
      end

      # Short cut for setting up a Mongocore::Query object
      def qq(*args)
        Mongocore::Query.new(*args)
      end

    end
  end
end
