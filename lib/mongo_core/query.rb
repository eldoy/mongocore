module MongoCore
  class Query

    attr_accessor :db, :model, :collection, :colname, :query, :options, :store

    # These options will be deleted before doing the find
    def initialize(m, q = {}, o = {}, s = {})
      # Support find passing a ID
      q = {:_id => oid(q)} if q.is_a?(String) or q.is_a?(BSON::ObjectId)

      # Mongodb wants _id as BSON::ObjectId, not id as String
      q[:_id] = oid(q.delete(:id)) if q[:id]

      # Storing model and db
      @model = m; @db = MongoCore.db

      # The model name is singular, the collection name is plural
      @colname = "#{m.to_s.downcase}s".to_sym

      # Storing the Mongo::Collection object
      @collection = @db[@colname]

      # Storing query and options. Sort and limit is stored in options
      s[:sort] ||= {}; s[:limit] ||= 0; s[:chain] ||= []; s[:source] ||= nil
      @options = o; @query = q; @store = s
    end

    # Convert string id into a BSON::ObjectId
    # Pass nothing or nil to get a new ObjectId
    def oid(id = nil)
      return id if id.is_a?(BSON::ObjectId)
      return BSON::ObjectId.new if !id
      BSON::ObjectId.from_string(id) rescue id
    end

    # Find. Returns a MongoCore::Query
    def find(q = {}, o = {})
      MongoCore::Query.new(@model, @query.merge(q), @options.merge(o))
    end

    # Count. Returns the number of documents as an integer
    def count
      chain || fetch(:count)
    end

    # Check if there's a corresponding counter for this count
    def chain(s = @store[:source], c = @store[:chain])
      r = s.send(%{#{@colname}#{c.present? ? "_#{c.join('_')}" : ''}_count}) rescue nil
      return r if r and r > 0
    end

    # Update
    def update(a)
      collection.update_one(@query, {'$set' => a}, :upsert => true)
    end

    # Delete
    def delete
      collection.delete_one(@query)
    end

    # Return first document
    def first(doc = nil)
      (doc ||= fetch(:first)) ? @model.new(doc.to_hash) : nil
    end

    # Return all documents
    def all
      self.fetch(:to_a).map{|d| first(d)}
    end

    # Fetch docs
    def fetch(n)
      # Do the find
      collection.find(@query, @options).sort(@store[:sort] || {}).limit(@store[:limit] || 0).send(n)
    end

    # Sort
    def sort(o = {})
      @store[:sort] = (store[:sort] || {}).merge!(o); self
    end

    # Limit
    def limit(n = 1)
      @store[:limit] = n; self
    end

    # Call and return the scope if it exists
    def method_missing(name, *arguments, &block)
      return @model.send(name, @query, @options, @store.tap{@store[:chain] << name}) if @model.scopes.has_key?(name)
      super
    end
  end
end
