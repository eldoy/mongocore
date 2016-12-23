module MongoCore
  module Document
    extend ActiveSupport::Concern

    # Setup model
    included do

      # Accessors, everything is writable if you need something dynamic.
      class << self
        attr_accessor :schema, :meta, :accessors, :keys, :many, :scopes, :defaults, :befores, :afters
      end

      # Load schema file
      f = File.join(MongoCore.schema, "#{self.to_s.downcase}.yml")
      begin
        @schema = YAML.load(File.read(f)).deep_symbolize_keys
      rescue
        puts "Schema file not found in #{f}, please add it."
        exit(0)
      end

      # Meta
      @meta = @schema[:meta] || {}

      # Keys
      @keys = @schema[:keys] || {}

      # Accessors
      (@accessors = @schema[:accessor] || []).each{|a| attr_accessor a.to_sym}

      # Many
      (@many = @schema[:many] || {}).each{|k, v| mny(k, v)}

      # Scopes
      (@scopes = @schema[:scopes] || {}).each{|k, v| scope(k, v)}

      # Defaults and foreign keys
      @defaults = {}
      @keys.each{|k, v| foreign(k, v); @defaults[k] = v[:default]}

      # The before filters
      @befores = Hash.new{|h, k| h[k] = []}

      # The after filters
      @afters = Hash.new{|h, k| h[k] = []}

      # Instance variables
      attr_accessor :db, :_id, :errors

      # The class initializer, called when you write Model.new
      # Pass in attributes you want to set: Model.new(:duration => 60)
      # Defaults are filled in automatically.
      def initialize(a = {})
        # Short cut for db
        @db ||= MongoCore.db

        # The errors hash
        @errors ||= Hash.new{|h, k| h[k] = []}

        # Defaults
        self.class.defaults.each{|k, v| write(k, v)}

        # Set the attributes
        a.each{|k, v| write(k, v)}

        # The _id has the BSON object
        write(:_id, BSON::ObjectId.new) unless @_id

        # The id has the string version
        write(:id, @_id.to_s)
      end

      # Save attributes to db
      def save(o = {})
        # Create a new query
        validate.tap{ return nil if errors.any?} if o[:validate] and self.respond_to?(:validate)
        qq(self.class, {:id => @id}).update(attributes).tap{run(:after, :save)}
      end

      # Update document in db
      def update(a = {})
        a.each{|k, v| write(k, v)}
        single.update(a).tap{run(:after, :update)}
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
        a = {}; self.class.keys.keys.each{|k| a[k] = send(k)}; a
      end

      # Available filters are :save, :update, :delete
      def run(filter, key)
        self.class.send(%{#{filter}s})[key].each{|e| e.is_a?(Proc) ? self.instance_eval(&e) : self.send(e)}
      end

      # Dynamically read or write the value
      def method_missing(name, *arguments, &block)
        # Extract name and write mode
        name =~ /([^=]+)(=)?/

        # Write or read
        if self.class.keys.has_key?(key = $1.to_sym)
          return write(key, arguments.first) if $2
          return read(key)
        end

        # Pass if nothing found
        super
      end

      private

      # Short cut for setting up a MongoCore::Query object
      def qq(*args)
        MongoCore::Query.new(*args)
      end

      # Short cut for simple query with cache buster
      def single(g = {:cache => false})
        qq(self.class, {:id => @id}, {}, g)
      end

      # Get attribute
      def read(key)
        instance_variable_get("@#{key}")
      end

      # Set attribute
      def write(key, val)
        instance_variable_set("@#{key}", strict(key, val))
      end

      # Strict type if val and schema type is set
      def strict(key, val)
        return nil if val.nil?
        type = self.class.keys[key][:type].to_sym rescue nil
        return val if type.nil?

        # Convert to the same type as in the schema
        return val.to_i if type == :integer and !val.is_a?(Integer)
        return val.to_f if type == :float   and !val.is_a?(Float)
        return !!val    if type == :boolean and !!val != val
        if type == :object_id and !val.is_a?(BSON::ObjectId)
          return BSON::ObjectId.from_string(val) rescue nil
        end
        val
      end
    end

    # Class methods
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

      # Register afters and befores. Pass a method name as symbol or a block
      # Possible filters are :save, :update, :delete
      def after(*args, &block)
        afters[args[0]] << (args[1] || block)
      end

      def before(*args, &block)
        befores[args[0]] << (args[1] || block)
      end

      private

      # Short cut for setting up a MongoCore::Query object
      def qq(*args)
        MongoCore::Query.new(*args)
      end

      # # # # #
      # Templates for foreign key, many-associations and scopes.
      # # # # #

      # Foreign keys
      def foreign(key, data)
        return unless key.to_s.ends_with?('_id')
        s = key[0..-4]
        t = %Q{
          def #{s}
            @#{s} ||= qq(#{s.capitalize}, :id => @#{key}).first
          end

          def #{s}=(m)
            @#{key} = m._id
            @#{s} = m
          end
        }
        class_eval t
      end

      # Many
      def mny(key, data)
        t = %Q{
          def #{key}
            qq(#{key[0..-2].capitalize}, {:#{self.to_s.downcase}_id => @_id}, {}, :source => self)
          end
        }
        class_eval t
      end

      # Set up scope and insert it
      def scope(key, data)
        # Extract the parameters
        pm = data.delete(:params) || []

        # Replace data if we are using parameters
        d = %{#{data}}
        pm.each do |a|
          d.scan(%r{(=>"(#{a})(\.[a-z0-9]+)?")}).each do |n|
            d.gsub!(n[0], %{=>#{n[1]}#{n[2]}})
          end
        end

        # Define the scope method so we can call it
        j = pm.any? ? %{#{pm.join(', ')},} : ''
        t = %Q{
          def #{key}(#{j} q = {}, o = {}, s = {})
            qq(self, q.merge(#{d}), o, {:scope => [:#{key}]}.merge(s))
          end
        }
        instance_eval t
      end

    end
  end
end
