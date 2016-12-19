module MongoCore
  module Document
    extend ActiveSupport::Concern

    # Class methods
    class_methods do
      # Find, takes an id or a hash
      def find(query = {}, options = {})
        MongoCore::Query.new(self).find(query, options)
      end

      # Count
      def count(query = {}, options = {})
        find(query, options).count
      end
    end

    # Setup model
    included do
      # Accessors, everything is writable if you need something dynamic.
      cattr_accessor :schema, :meta, :accessors, :keys, :belong, :many, :defaults

      # Load schema from root/config/db/schema/model_name.yml
      name = "#{self.to_s.downcase}.yml"
      path = File.join(Dir.pwd, 'config', 'db', 'schema', name)
      begin
        @@schema = YAML.load(File.read(path)).deep_symbolize_keys
      rescue
        puts "Schema not found in #{path}, please add it."
        exit(0)
      end

      # Extract data
      @@meta = @@schema[:meta] || {}
      @@accessors = @@schema[:accessor] || []
      @@keys = @@schema[:keys] || {}
      @@belong = @@schema[:belong] || {}
      @@many = @@schema[:many] || {}

      # Accessors
      @@accessors.each{|a| attr_accessor a.to_sym}

      # Defaults
      @@defaults = {}
      @@keys.each{|k, v| @@defaults[k] = v[:default]}

      # Instance variables
      attr_accessor :db, :_id

      # The class initializer, called when you write Model.new
      # Pass in attributes you want to set: Model.new(:duration => 60)
      # Defaults are filled in automatically.
      def initialize(a = {})
        # Short cut for db
        @db ||= MongoCore.db

        # Defaults
        @@defaults.each{|k, v| write_attribute(k, v)}

        # Set the attributes
        a.each{|k, v| write_attribute(k, v)}

        # Add IDs. The _id has the BSON object, the id has the string
        write_attribute(:_id, BSON::ObjectId.new)
        write_attribute(:id, @_id.to_s)
      end

      # Save attributes to db
      def save(options = {})
        # Create a new query
        query = MongoCore::Query.new(self.class, {:id => @id}, options)
        query.update(attributes)
      end

      # Update document in db
      def update(a = {})
        a.each{|k, v| write_attribute(k, v)}
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
        a = {};@@keys.keys.each{|k| a[k] = send(k)};a
      end

      # Method missing. Here we set up variables
      def method_missing(name, *arguments, &block)
        # puts "\n\n!!!!!!!!!!!!!!!!!"
        # puts name
        # puts name.class
        # puts arguments

        # Extract name and mode
        key = name.to_s
        if key.ends_with?('=')
          key = key[0..-2]
          write = true
        end
        key = key.to_sym

        # puts "MISSING: #{key} #{setter}"

        # Dynamically read or write the value
        if @@keys.has_key?(key)
          return write_attribute(key, arguments.first) if write
          return read_attribute(key)
        end

        super
      end

      private

      # Set attribute
      def write_attribute(key, val)
        instance_variable_set("@#{key}", strict(key, val))
      end

      # Get attribute
      def read_attribute(key)
        instance_variable_get("@#{key}")
      end

      # Strict type if val and schema type is set
      def strict(key, val)
        return nil if val.nil?
        type = @@keys[key][:type].to_sym rescue nil
        return val if type.nil?

        # Convert to the same type as in the schema
        case type
        when :integer then val.to_i
        when :float   then val.to_f
        when :boolean then !!val
        else val
        end
      end

    end
  end
end
