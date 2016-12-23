module MongoCore
  class Query

    attr_accessor :db, :model, :collection, :colname, :query, :options, :store, :cache

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

      # Generate cache key
      @cache ||= generate
    end

    # Generate the cache key
    def generate
       Digest::MD5.hexdigest(%{#{@model}#{@query.sort}#{@options.sort}#{@store[:chain]}#{@store[:sort]}#{@store[:limit]}})
    end

    # Convert string id into a BSON::ObjectId
    # Pass nothing or nil to get a new ObjectId
    def oid(id = nil)
      return id if id.is_a?(BSON::ObjectId)
      return BSON::ObjectId.new if !id
      BSON::ObjectId.from_string(id) rescue id
    end

    # Find. Returns a MongoCore::Query
    def find(q = {}, o = {}, s = {})
      MongoCore::Query.new(@model, @query.merge(q), @options.merge(o), @store.merge(s))
    end

    # Count. Returns the number of documents as an integer
    def count
      counter || fetch(:count)
    end

    # Check if there's a corresponding counter for this count
    def counter(s = @store[:source], c = @store[:chain])
      n = s.send(%{#{@colname}#{c.present? ? "_#{c.join('_')}" : ''}_count}) rescue nil
      return n if n and n > 0
    end

    # Update
    def update(a)
      MongoCore::Cache.update(self, a)
    end

    # Delete
    def delete
      MongoCore::Cache.delete(self)
    end

    # Return first document
    def first(doc = nil)
      (doc ||= fetch(:first)) ? @model.new(doc.to_hash) : nil
    end

    # Return all documents
    def all
      self.fetch(:to_a).map{|d| first(d)}
    end

    # Fetch docs, pass type :first, :to_a or :count
    def fetch(type)
      MongoCore::Cache.find(self, type)
    end

    # Cache key
    def cac(type)
      @ck ||= %{#{type}}
    end

    # Sort
    def sort(o = {})
      find(@query, @options, @store.tap{@store[:sort].merge(o)})
    end

    # Limit
    def limit(n = 1)
      find(@query, @options, @store.tap{@store[:limit] = n})
    end

    # Call and return the scope if it exists
    def method_missing(name, *arguments, &block)
      return @model.send(name, @query, @options, @store.tap{@store[:chain] << name}) if @model.scopes.has_key?(name)
      super
    end
  end
end
