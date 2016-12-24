module MongoCore
  module Document

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        # Accessors, everything is writable if you need something dynamic.
        class << self
          attr_accessor :schema, :meta, :accessors, :keys, :many, :scopes, :defaults, :befores, :afters
        end

        # Load schema file
        f = File.join(MongoCore.schema, "#{self.to_s.downcase}.yml")
        begin
          @schema = YAML.load(File.read(f)).deep_symbolize_keys
        rescue => e
          puts "Schema file not found in #{f}, please add it."
          exit(0)
        end

        # Meta
        @meta = @schema[:meta] || {}

        # Keys
        @keys = @schema[:keys] || {}

        # Accessors
        (@accessors = @schema[:accessor] || []).each{|a| attr_accessor(a.to_sym)}

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
        # @db holds the MongoCore.db
        # @errors is used for validations
        # @changes keeps track of object changes
        # @saved indicates whether this is saved or not
        attr_accessor :db, :errors, :changes, :saved

        # The class initializer, called when you write Model.new
        # Pass in attributes you want to set: Model.new(:duration => 60)
        # Defaults are filled in automatically.
        def initialize(a = {})
          a = a.deep_symbolize_keys

          # The _id has the BSON object, create new unless it exists
          a[:_id] ? @saved = true : a[:_id] = BSON::ObjectId.new

          # Short cut for db
          @db ||= MongoCore.db

          # The errors hash
          @errors ||= Hash.new{|h, k| h[k] = []}

          # Defaults
          self.class.defaults.each{|k, v| write(k, v)}

          # Set the attributes
          a.each{|k, v| write(k, v)}

          # The changes hash
          @changes ||= Hash.new{|h, k| h[k] = []}
        end

        # Save attributes to db
        def save(o = {})
          # Create a new query
          validate.tap{ return nil if errors.any?} if o[:validate] and self.respond_to?(:validate)
          qq(self.class, {:_id => @_id}).update(attributes).tap{@saved = true; run(:after, :save)}
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
          a = {}; self.class.keys.keys.each{|k| a[k] = read!(k)}; a
        end

        # Set the attributes
        def attributes=(a)
          a.each{|k, v| write!(k, v)}
        end

        # Changed?
        def changed?
          changes.any?
        end

        # Saved? Persisted?
        def saved?; !!@saved; end

        # Unsaved? New record?
        def unsaved?; !@saved; end

        # Available filters are :save, :update, :delete
        def run(filter, key)
          self.class.send(%{#{filter}s})[key].each{|e| e.is_a?(Proc) ? self.instance_eval(&e) : self.send(e)}
        end

        # Dynamically read or write attributes
        def method_missing(name, *arguments, &block)
          # Extract name and write mode
          name =~ /([^=]+)(=)?/

          # Write or read
          if self.class.keys.has_key?(key = $1.to_sym)
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

        private

        # Short cut for setting up a MongoCore::Query object
        def qq(*args)
          MongoCore::Query.new(*args)
        end

        # Short cut for simple query with cache buster
        def single(g = {:cache => false})
          qq(self.class, {:_id => @_id}, {}, g)
        end

        # Access?
        def access?(mode, key)
          return true unless MongoCore.access
          case mode
          when :read then MongoCore::Access.new(self).read?(key)
          when :write then MongoCore::Access.new(self).write?(key)
          end
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
          type = self.class.keys[key][:type].to_sym rescue nil
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
      end
    end

    # Class methods
    module ClassMethods

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
        return if key !~ /(.+)_id/
        t = %Q{
          def #{$1}
            @#{$1} ||= qq(#{$1.capitalize}, :_id => @#{key}).first
          end

          def #{$1}=(m)
            @#{key} = m._id
            @#{$1} = m
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
