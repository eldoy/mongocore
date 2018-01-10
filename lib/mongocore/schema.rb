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
      (@many = @schema[:many] || []).each{|k| many(k)}

      # Scopes
      (@scopes = @schema[:scopes] || {}).each{|k, v| scope(k, v)}

      # Defaults and foreign keys
      @defaults = {}; @keys.each{|k, v| foreign(k, v); @defaults[k] = v[:default]}
    end

    # Get attributes that has these tags
    def attributes(tags)
      (tags[0] ? @keys.select{|k, v| v[:tags] & tags} : @keys).keys
    end

    # Get time
    def time(val)
      case val
      when Date then val.to_time.utc
      when String then Time.parse(val).utc
      when Time then val.utc
      else nil
      end
    end

    # Convert type if val and schema type is set
    def convert(key, val)
      return nil if val.nil?
      case type(key)
      when :string       then val.to_s
      when :integer      then val.to_i
      when :time         then time(val)
      when :float        then val.to_f
      when :boolean      then val.to_s.to_bool
      when :object_id    then oid(val)
      when :array, :hash then ids(val)
      else val
      end
    end

    # Setup query, replace :id with :_id, set up object ids
    def ids(h)
      transform(h).each do |k, v|
        case v
        when Hash
          # Call hashes recursively
          ids(v)
        when Array
          # Return mapped array or recurse hashes
          v.map!{|r| r.is_a?(Hash) ? ids(r) : oid(r)}
        else
          # Convert to object ID if applicable
          h[k] = oid(v) if v.is_a?(String)
        end
      end
    end

    # Transform :id to _id or id to object id
    def transform(e)
      e.is_a?(Hash) ? e.transform_keys!{|k| k == :id ? :_id : k} : e.map!{|r| oid(r)}
    end

    # Find type as defined in schema
    def type(key)
      @keys[key][:type].to_sym rescue :string
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
          @#{key} = m._id rescue (BSON::ObjectId.from_string(m) rescue m)
          @#{$1} = m
        end
      }
      @klass.class_eval t
    end

    # Many
    def many(key)
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
