module Mongocore
  class Query

    # # # # # # # #
    # The Query class keeps the cursor and handles the connection with the
    # underlying MongoDB database. A new query is created every time you call
    # find, sort, limit, count, update, scopes and associations.
    #
    # Every query can be chained, but only one find is ever done to the database,
    # it's only the parameters that change.
    #

    attr_accessor :db, :model, :collection, :colname, :query, :options, :store, :cache

    # These options will be deleted before doing the find
    def initialize(m, q = {}, o = {}, s = {})
      # Support find passing a ID
      q = {:_id => oid(q)} unless q.is_a?(Hash)

      # Storing model and db
      @model = m; @db = Mongocore.db

      # The model name is singular, the collection name is plural
      @colname = "#{m.to_s.downcase}s".to_sym

      # Storing the Mongo::Collection object
      @collection = @db[@colname]

      # Storing query and options. Sort and limit is stored in options
      s[:sort] ||= {}; s[:limit] ||= 0; s[:chain] ||= []; s[:source] ||= nil
      @options = o; @query = q; @store = s

      # Set up cache
      @cache = Mongocore::Cache.new(self)
    end

    # Convert string id into a BSON::ObjectId
    # Pass nothing or nil to get a new ObjectId
    def oid(id = nil)
      return id if id.is_a?(BSON::ObjectId)
      return BSON::ObjectId.new if !id
      BSON::ObjectId.from_string(id) rescue id
    end

    # Find. Returns a Mongocore::Query
    def find(q = {}, o = {}, s = {})
      Mongocore::Query.new(@model, @query.merge(q), @options.merge(o), @store.merge(s))
    end

    # Count. Returns the number of documents as an integer
    def count
      counter || fetch(:count)
    end

    # Check if there's a corresponding counter for this count
    def counter(s = @store[:source], c = @store[:chain])
      s.send(%{#{@colname}#{c.present? ? "_#{c.join('_')}" : ''}_count}.to_sym) rescue nil
    end

    # Update
    def update(a)
      # We do $set on non nil, $unset on nil
      atts = {
        :$set => a.select{|k, v| !v.nil?},
        :$unset => a.select{|k, v| v.nil?}
      }.delete_if{|k, v| v.empty?}

      puts "UPDATE: #{atts.inspect}" if Mongocore.debug

      collection.update_one(query, atts, :upsert => true)
    end

    # Delete
    def delete
      collection.delete_one(query)
    end

    # Return first document
    def first(doc = nil)
      (doc ||= fetch(:first)) ? @model.new(doc.to_hash) : nil
    end

    # Return last document
    def last
      sort(:_id => -1).limit(1).first
    end

    # Return all documents
    def all
      self.fetch(:to_a).map{|d| first(d)}
    end

    # Fetch docs, pass type :first, :to_a or :count
    def fetch(t)
      cache.get(t) if Mongocore.cache

      # Fetch from mongodb and add to cache
      cursor.send(t).tap{|r| cache.set(t, r) if Mongocore.cache}
    end

    # Cursor
    def cursor
      collection.find(query, options).sort(store[:sort]).limit(store[:limit])
    end

    # Sort
    def sort(o = {})
      find(query, options, store.tap{store[:sort].merge!(o)})
    end

    # Limit
    def limit(n = 1)
      find(query, options, store.tap{store[:limit] = n})
    end

    # Cache key
    def key
      @key ||= "#{model}#{query.sort}#{options.sort}#{store.values}"
    end

    # Call and return the scope if it exists
    def method_missing(name, *arguments, &block)
      return @model.send(name, @query, @options, @store.tap{@store[:chain] << name}) if @model.schema.scopes.has_key?(name)
      super
    end

  end
end
