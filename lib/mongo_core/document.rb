module MongoCore
  module Document
    extend ActiveSupport::Concern

    # Setup model
    included do
      # Accessors, everything is writable if you need something dynamic.
      cattr_accessor :schema, :meta, :accessors, :keys, :many, :scopes, :defaults

      # Load schema from root/config/db/schema/model_name.yml
      name = "#{self.to_s.downcase}.yml"
      path = File.join(Dir.pwd, 'config', 'db', 'schema', name)
      begin
        @@schema = YAML.load(File.read(path)).deep_symbolize_keys
      rescue
        puts "Schema not found in #{path}, please add it."
        exit(0)
      end

      # Meta
      @@meta = @@schema[:meta] || {}

      # Keys
      @@keys = @@schema[:keys] || {}

      # Accessors
      @@accessors = @@schema[:accessor] || []
      @@accessors.each{|a| attr_accessor a.to_sym}

      # Many
      @@many = @@schema[:many] || {}
      @@many.each{|k, v| manys(k, v)}

      # Scopes
      @@scopes = @@schema[:scopes] || {}
      @@scopes.each{|k, v| scope(k, v)}

      # Defaults and
      @@defaults = {}
      @@keys.each do |k, v|
        @@defaults[k] = v[:default]
        # Set up accessor for keys that end with _id
        one(k, v) if k.to_s.ends_with?('_id')
      end

      # Instance variables
      attr_accessor :db, :_id

      # The class initializer, called when you write Model.new
      # Pass in attributes you want to set: Model.new(:duration => 60)
      # Defaults are filled in automatically.
      def initialize(a = {})
        # Short cut for db
        @db ||= MongoCore.db

        # Defaults
        @@defaults.each{|k, v| write(k, v)}

        # Set the attributes
        a.each{|k, v| write(k, v)}

        # The _id has the BSON object
        write(:_id, BSON::ObjectId.new)

        # The id has the string version
        write(:id, @_id.to_s)
      end

      # Save attributes to db
      def save(options = {})
        # Create a new query
        query = MongoCore::Query.new(self.class, {:id => @id}, options)
        query.update(attributes)
      end

      # Update document in db
      def update(a = {})
        a.each{|k, v| write(k, v)}
        MongoCore::Query.new(self.class, :id => @id).update(a)
      end

      # Delete a document in db
      def delete
        MongoCore::Query.new(self.class, :id => @id).delete
      end

      # Reload the document from db
      def reload
        MongoCore::Query.new(self.class, :id => @id).first
      end

      # Collect the attributes
      def attributes
        a = {}; @@keys.keys.each{|k| a[k] = send(k)}; a
      end

      # Method missing. Here we set up variables.
      def method_missing(name, *arguments, &block)
        # Extract name and write mode
        name =~ /([^=]+)(=)?/
        key = $1.to_sym

        # Dynamically read or write the value
        if @@keys.has_key?(key)
          return write(key, arguments.first) if $2
          return read(key)
        end

        # Pass
        super
      end

      private

      # Set attribute
      def write(key, val)
        instance_variable_set("@#{key}", strict(key, val))
      end

      # Get attribute
      def read(key)
        instance_variable_get("@#{key}")
      end

      # Strict type if val and schema type is set
      def strict(key, val)
        return nil if val.nil?
        type = @@keys[key][:type].to_sym rescue nil
        return val if type.nil?

        # Convert to the same type as in the schema
        return val.to_i if type == :integer and !val.is_a?(Integer)
        return val.to_f if type == :float   and !val.is_a?(Float)
        return !!val    if type == :boolean and !!val != val
        if type == :object_id and !val.is_a?(BSON::ObjectId)
          return (BSON::ObjectId.from_string(val) rescue nil)
        end
        val
      end
    end

    # Class methods
    class_methods do

      # Find, takes an id or a hash
      def find(query = {}, options = {})
        MongoCore::Query.new(self, query, options)
      end

      # Count
      def count(query = {}, options = {})
        find(query, options).count
      end

      # First
      def first(query = {}, options = {})
        find(query, options).first
      end

      # One
      def one(name, data)
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
      def manys(name, data)
        t = %Q{
          def #{name}
            MongoCore::Query.new(self, :#{self.to_s.downcase}_id => @id)
          end
        }
        instance_eval t
      end

      # Set up scope and insert it
      def scope(name, data)
        params = data.delete(:params) || []

        # Define the scope method so we can call it
        j = params.any? ? %{#{params.join(', ')},} : ''
        t = %Q{
          def #{name}(#{j} q = {}, o = {})
            MongoCore::Query.new(self, q.merge(#{data}), o)
          end
        }

        # Replace data if we are using parameters
        params.each do |a|
          t.scan(%r{(=>"(#{a})(\.[a-z0-9]{1,})?")}).each do |n|
            t.gsub!(n[0], %{=>#{n[1]}#{n[2]}})
          end
        end

        # Add the method to the class
        instance_eval t
      end
    end

  end
end
