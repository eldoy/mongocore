module MongoCore
  module Document
    extend ActiveSupport::Concern

    # Setup model
    included do

      # Accessors, everything is writable if you need something dynamic.
      class << self
        attr_accessor :schema, :meta, :accessors, :keys, :many, :scopes, :defaults, :events, :test
      end

      # Load schema from root/config/db/schema/model_name.yml
      f = File.join(Dir.pwd, 'config', 'db', 'schema', "#{self.to_s.downcase}.yml")
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

      # The events hash
      @events = Hash.new{|h, k| h[k] = []}

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
        q = MongoCore::Query.new(self.class, {:id => @id}, o)
        q.update(attributes).tap{run(:save)}
      end

      # Update document in db
      def update(a = {})
        a.each{|k, v| write(k, v)}
        MongoCore::Query.new(self.class, :id => @id).update(a).tap{run(:update)}
      end

      # Delete a document in db
      def delete
        MongoCore::Query.new(self.class, :id => @id).delete.tap{run(:delete)}
      end

      # Reload the document from db
      def reload
        MongoCore::Query.new(self.class, :id => @id).first
      end

      # Collect the attributes
      def attributes
        a = {}; self.class.keys.keys.each{|k| a[k] = send(k)}; a
      end

      # Run events, available events are :save, :update, :delete
      def run(name)
        self.class.events[name].each{|e| e.is_a?(Proc) ? self.instance_eval(&e) : self.send(e)}
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
      def find(q = {}, o = {}, s = {})
        MongoCore::Query.new(self, q, o, s)
      end

      # Count
      def count(q = {}, o = {})
        find(q, o).count
      end

      # First
      def first(q = {}, o = {})
        find(q, o).first
      end

      # All
      def all(q = {}, o = {})
        find(q, o).all
      end

      # Sort
      def sort(o = {})
        find({}, {}, :sort => o)
      end

      # Limit
      def limit(n = 1)
        find({}, {}, :limit => n)
      end

      # Register events. Pass a method name as symbol or a block
      # Possible events are :save, :update, :delete
      def event(*args, &block)
        events[args[0]] << (args[1] || block)
      end

      # # # # #
      # Templates for foreign key, many-associations and scopes.
      # # # # #
      private

      # Foreign keys
      def foreign(name, data)
        return unless name.to_s.ends_with?('_id')
        s = name[0..-4]
        t = %Q{
          def #{s}
            @#{s} ||= MongoCore::Query.new(#{s.capitalize}, :id => @#{name}).first
          end

          def #{s}=(m)
            @#{name} = m._id
            @#{s} = m
          end
        }
        class_eval t
      end

      # Many
      def mny(name, data)
        t = %Q{
          def #{name}
            MongoCore::Query.new(#{name[0..-2].capitalize}, {:#{self.to_s.downcase}_id => @_id}, {}, :source => self)
          end
        }
        class_eval t
      end

      # Set up scope and insert it
      def scope(name, data)
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
          def #{name}(#{j} q = {}, o = {}, s = {})
            MongoCore::Query.new(self, q.merge(#{d}), o, {:scope => [:#{name}]}.merge(s))
          end
        }
        instance_eval t
      end

    end
  end
end
