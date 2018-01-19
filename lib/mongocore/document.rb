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
      # @persisted indicates whether this is saved or not
      #

      attr_accessor :errors, :changes, :persisted, :original

      # # # # # # # # # # #
      # The class initializer, called when you write Model.new
      # Pass in attributes you want to set: Model.new(:duration => 60)
      # Defaults are filled in automatically.
      #
      def initialize(a = {})

        # Store attributes.
        self.attributes = @_id ? a : self.class.schema.defaults.merge(a)

        # Storing original state for dirty tracking.
        @original = self.attributes

        # The _id is a BSON object, create new unless it exists
        @_id ? @persisted = true : @_id = BSON::ObjectId.new

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
        self.attributes = a; save(o)
      end

      # Delete a document in db
      def delete
        filter(:delete, false){one.delete}
      end

      # Run filters before and after accessing the db
      def filter(cmd, persisted = true, &block)
        run(:before, cmd); yield.tap{@persisted = persisted; run(:after, cmd); reset!}
      end

      # Reload the document from db and update attributes
      def reload
        one.first.tap{|m| self.attributes = m.attributes; reset!}
      end

      # Set the timestamps if enabled
      def timestamps
        t = Time.now.utc; @updated_at = t; @created_at = t if unsaved?
      end

      # Reset internals
      def reset!
        @original = self.attributes; @changes.clear; @errors.clear
      end


      # # # # # # # # # # # # # # # #
      # Attribute methods
      #

      # Collect the attributes, pass tags like defined in your model yml
      def attributes(*tags)
        a = {}; self.class.schema.attributes(tags.map(&:to_s)).each{|k| a[k] = read(k)}; a
      end

      # Set the attributes
      def attributes=(a)
        a.deep_symbolize_keys.each{|k, v| write(k, v)}
      end

      # Changed?
      def changed?
        @changes.any?
      end

      # JSON format
      def as_json(o = {})
        string_id(attributes(*o[:data]))
      end

      # # # # # # # # # # # # # # # #
      # Validation methods
      #

      # Valid?
      def valid?
        @errors.clear; self.class.filters.valid?(self)
      end

      # Available filters are :save, :update, :delete
      def run(filter, key = nil)
        self.class.filters.run(self, filter, key)
      end


      # # # # # # # # # # # # # # # #
      # Convenience methods
      #

      # Saved? Persisted?
      def saved?; !!@persisted; end
      alias_method :persisted?, :saved?

      # Unsaved? New record?
      def unsaved?; !@persisted; end
      alias_method :new_record?, :unsaved?

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
        self.class.access.read?((key = key.to_sym)) ? read!(key) : nil
      end

      # Get attribute
      def read!(key)
        instance_variable_get("@#{key}")
      end

      # Set attribute if access
      def write(key, val)
        return nil unless self.class.access.write?((key = key.to_sym))

        # Convert to type as in schema yml
        v = self.class.schema.convert(key, val)

        # Record change for dirty attributes
        read!(key).tap{|r| @changes[key] = [@original[key], v] if v != r} if @changes

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
          return $2 ? write(key, args.first) : read(key)
        end

        # Attributes changed?
        return @changes.has_key?($1.to_sym) if key =~ /(.+)_changed\?/

        # Attributes was
        return @original[$1.to_sym] if key =~ /(.+)_was/

        # Pass if nothing found
        super
      end

      # Alias for _id but returns string
      def id
        @_id ? @_id.to_s : nil
      end

      # Assign id
      def id=(val)
        @_id = val.is_a?(BSON::ObjectId) ? val : BSON::ObjectId.from_string(val)
      end

      # Print info about the instance
      def inspect
        "#<#{self.class} #{attributes.sort.map{|r| %{#{r[0]}: #{r[1].inspect}}}.join(', ')}>"
      end

      private

      # Persist for save and update
      def persist(type, o)
        # Send :validate => true to validate
        return false unless valid? if o[:validate]

        # Create a new query
        filter(type){one.send((@persisted ? :update : :insert), attributes).ok?}
      end

      # Replace _id with id, takes a hash
      def string_id(a)
        a.delete(:_id); {:id => id}.merge(a)
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
      alias_method :where, :find

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

      # Paginate
      def paginate(*args)
        find({}).paginate(*args)
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

      # Projection
      def projection(o = {})
        find({}, {}, :projection => o)
      end
      alias_method :fields, :projection

      # Insert
      def insert(a = {}, o = {})
        new(a).tap{|r| r.save(o)}
      end
      alias_method :create, :insert

      # Each
      def each(&block)
        find.each{|r| yield(r)}
      end

      # Each with index
      def each_with_index(&block)
        find.each_with_index{|r, n| yield(r, n)}
      end

      # Each with object
      def each_with_object(obj, &block)
        find.each_with_object(obj){|r, o| yield(r, o)}
      end

      # Map
      def map(&block)
        find.map{|r| yield(r)}
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
