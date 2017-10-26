module Mongocore
  class Schema

    # # # # # # # #
    # The Schema class is responsible for the schema handling.
    #

    # Accessors
    attr_accessor :klass, :path, :schema, :meta, :accessors, :keys, :many, :scopes, :defaults

    # Init
    def initialize(klass)
      # Store the document
      @klass = klass

      # Schema path
      @path = File.join(Mongocore.schema, "#{@klass.to_s.downcase}.yml")

      # Load schema
      @schema = YAML.load(File.read(@path)).deep_symbolize_keys

      # Meta
      @meta = @schema[:meta] || {}

      # Keys
      @keys = @schema[:keys] || {}

      # Accessors
      (@accessors = @schema[:accessor] || []).each{|a| @klass.send(:attr_accessor, a)}

      # Many
      (@many = @schema[:many] || {}).each{|k, v| many(k, v)}

      # Scopes
      (@scopes = @schema[:scopes] || {}).each{|k, v| scope(k, v)}

      # Defaults and foreign keys
      @defaults = {}; @keys.each{|k, v| foreign(k, v); @defaults[k] = v[:default]}
    end

    # Get attributes that has these tags
    def attributes(tags)
      (tags[0] ? @keys.select{|k, v| v[:tags] & tags} : @keys).keys
    end

    # Convert type if val and schema type is set
    def convert(key, val)
      return nil if val.nil?
      case find_type(key)
      when :string
        val.to_s
      when :integer
        val.to_i
      when :float
        val.to_f
      when :boolean
        val.to_s.to_bool
      when :object_id
        # Convert string id to BSON::ObjectId
        val.each do |k, v|
          val[k] = oid(v) if v.is_a?(String)
        end if val.is_a?(Hash)
        oid(val)
      else
        val
      end
    end

    # Find type as defined in schema
    def find_type(key)
      @keys[key][:type].to_sym rescue :string
    end

    # This key is a BSON::Object ID?
    def oid?(key)
      find_type(key) === :object_id
    end

    # Convert to BSON::ObjectId
    def oid(id = nil)
      return id if id.is_a?(BSON::ObjectId)
      return BSON::ObjectId.new if !id
      BSON::ObjectId.from_string(id) rescue id
    end

    # # # # # # # # #
    # Templates for foreign key, many-associations and scopes.
    #

    # Foreign keys
    def foreign(key, data)
      return if key !~ /(.+)_id/
      t = %Q{
        def #{$1}
          @#{$1} ||= mq(#{$1.capitalize}, :_id => @#{key}).first
        end

        def #{$1}=(m)
          @#{key} = m._id
          @#{$1} = m
        end
      }
      @klass.class_eval t
    end

    # Many
    def many(key, data)
      t = %Q{
        def #{key}
          mq(#{key.to_s.singularize.capitalize}, {:#{@klass.to_s.downcase}_id => @_id}, {}, :source => self)
        end
      }
      @klass.class_eval t
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
          mq(self, q.merge(#{d}), o, {:scope => [:#{key}]}.merge(s))
        end
      }
      @klass.instance_eval t
    end

  end
end
