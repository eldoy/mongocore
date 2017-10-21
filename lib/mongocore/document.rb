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
    # The model instance, m, lets you do operations on a model
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
      # @errors is used for validates
      # @changes keeps track of object changes
      # @saved indicates whether this is saved or not
      #

      attr_accessor :errors, :changes, :saved

      # # # # # # # # # # #
      # The class initializer, called when you write Model.new
      # Pass in attributes you want to set: Model.new(:duration => 60)
      # Defaults are filled in automatically.
      #
      def initialize(a = {})

        # Defaults
        self.attributes = self.class.schema.defaults.merge(a)

        # The _id is a BSON object, create new unless it exists
        @_id ? @saved = true : @_id = BSON::ObjectId.new

        # The errors hash
        @errors = Hash.new{|h, k| h[k] = []}

        # The changes hash
        @changes = Hash.new{|h, k| h[k] = []}
      end

      # # # # # # # # # # # #
      # Model methods are called with m = Model.new, m.method_name
      # # # # # # # # # # # # # # # # # #
      #
      # Database methods
      #

      # Save attributes to db
      def save(o = {})
        persist(:save, o)
      end

      # Update document in db
      def update(a = {}, o = {})
        self.attributes = a; persist(:update, o)
      end

      # Delete a document in db
      def delete
        filter(:delete, false){one.delete}
      end

      # Run filters before and after accessing the db
      def filter(cmd, saved = true, &block)
        run(:before, cmd); yield.tap{@saved = saved; run(:after, cmd)}
      end

      # Reload the document from db and update attributes
      def reload
        one.first.tap{|m| self.attributes = m.attributes}
      end

      # Set the timestamps if enabled
      def timestamps
        t = Time.now.utc; @updated_at = t; @created_at = t if unsaved?
      end


      # # # # # # # # # # # # # # # #
      # Attribute methods
      #

      # Collect the attributes, pass tags like defined in your model yml
      def attributes(*tags)
        a = {}; self.class.schema.attributes(tags.map(&:to_s)).each{|k| a[k] = read!(k)}; a
      end

      # Set the attributes
      def attributes=(a)
        a.deep_symbolize_keys.each{|k, v| write(k, v)}
      end

      # Changed?
      def changed?
        changes.any?
      end

      # JSON format
      def as_json(options = {})
        string_id(attributes)
      end


      # # # # # # # # # # # # # # # #
      # Validation methods
      #

      # Valid?
      def valid?
        self.class.filters.valid?(self)
      end

      # Available filters are :save, :update, :delete
      def run(filter, key = nil)
        self.class.filters.run(self, filter, key)
      end


      # # # # # # # # # # # # # # # #
      # Convenience methods
      #

      # Saved? Persisted?
      def saved?; !!@saved; end

      # Unsaved? New record?
      def unsaved?; !@saved; end

      # Short cut for setting up a Mongocore::Query object
      def mq(m, q = {}, o = {}, s = {})
        Mongocore::Query.new(m, q, o, {:source => self}.merge(s))
      end

      # Short cut for query needing only id
      def one(s = {})
        mq(self.class, {:_id => @_id}, {}, s)
      end


      # # # # # # # # # # # # # # # #
      # Read and write instance variables
      #

      # Get attribute if access
      def read(key)
        self.class.access.read?(key) ? read!(key) : nil
      end

      # Get attribute
      def read!(key)
        instance_variable_get("@#{key}")
      end

      # Set attribute if access
      def write(key, val)
        return nil unless self.class.access.write?(key)

        # Convert to type as in schema yml
        v = self.class.schema.convert(key, val)

        # Record change for dirty attributes
        read!(key).tap{|r| @changes[key] = r if v != r} if @changes

        # Write attribute
        write!(key, v)
      end

      # Set attribute
      def write!(key, v)
        instance_variable_set("@#{key}", v)
      end

      # Dynamically read or write attributes
      def method_missing(name, *args, &block)
        # Extract name and write mode
        name =~ /([^=]+)(=)?/

        # Write or read
        if self.class.schema.keys.has_key?(key = $1.to_sym)
          return write(key, args.first) if $2
          return read(key)
        end

        # Attributes changed?
        return changes.has_key?($1.to_sym) if key =~ /(.+)_changed\?/

        # Attributes was
        return changes[$1.to_sym] if key =~ /(.+)_was/

        # Pass if nothing found
        super
      end

      # Alias for _id but returns string
      def id
        @_id ? @_id.to_s : nil
      end

      # Replace _id with id, takes a hash
      def string_id(a)
        a.delete(:_id); {:id => id}.merge(a)
      end

      private

      # Persist for save and update
      def persist(type, o)
        # Send :validate => true to validate
        return false unless valid? if o[:validate]

        # Create a new query
        filter(type){one.update(attributes).ok?}
      end

    end


    # # # # # # # # # # # # # # #
    # Class methods are mostly database lookups and filters
    #

    class_methods do

      # Find, takes an id or a hash
      def find(*args)
        mq(self, *args)
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
      def last(*args)
        sort(:_id => -1).limit(1).first(*args)
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

      # Skip
      def skip(n = 0)
        find({}, {}, :skip => n)
      end

      # Fields (projection)
      def fields(o = {})
        find({}, {}, :fields => o)
      end


      # # # # # # # # #
      # After, before and validation filters
      # Pass a method name as symbol or a block
      #
      # Possible events for after and before are :save, :update, :delete
      #

      # After
      def after(*args, &block)
        filters.after[args[0]] << (args[1] || block)
      end

      # Before
      def before(*args, &block)
        filters.before[args[0]] << (args[1] || block)
      end

      # Validate
      def validate(*args, &block)
        filters.validate << (args[0] || block)
      end

      # Short cut for setting up a Mongocore::Query object
      def mq(*args)
        Mongocore::Query.new(*args)
      end

    end
  end
end
