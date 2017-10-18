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

    attr_accessor :model, :collection, :colname, :query, :options, :store, :cache

    # Mongocore query initializer
    def initialize(m, q = {}, o = {}, s = {})

      # Storing model class. The instance can be found in store[:source]
      @model = m

      # The model name is singular, the collection name is plural
      @colname = m.to_s.downcase.pluralize.to_sym

      # Storing the Mongo::Collection object
      @collection = Mongocore.db[@colname]

      # Storing query and options. Sort and limit is stored in options
      s[:sort] ||= {}; s[:limit] ||= 0; s[:chain] ||= []; s[:source] ||= nil; s[:fields] ||= {}; s[:skip] ||= 0
      @query, @options, @store = normalize(q), o, s

      # Set up cache
      @cache = Mongocore::Cache.new(self)
    end

    # Find. Returns a Mongocore::Query
    def find(q = {}, o = {}, s = {})
      self.class.new(@model, @query.merge(normalize(q)), @options.merge(o), @store.merge(s))
    end

    # Normalize query
    def normalize(q)
      # Support find passing an ID
      q = {:_id => oid(q)} unless q.is_a?(Hash)

      # Support passing :id as :_id
      q[:_id] = q.delete(:id) if q[:id]

      # Convert object ID's to BSON::ObjectIds
      q.each{|k, v| q[k] = oid(v) if k =~ /_id$/}

      q
    end

    # Cursor
    def cursor
      @collection.find(@query, @options).projection(@store[:fields]).skip(@store[:skip]).sort(@store[:sort]).limit(@store[:limit])
    end

    # Update
    def update(a)
      # We do $set on non nil, $unset on nil
      u = {
        :$set => a.select{|k, v| !v.nil?}, :$unset => a.select{|k, v| v.nil?}
      }.delete_if{|k, v| v.empty?}

      # Update the collection
      @collection.update_one(@query, u, :upsert => true)
    end

    # Delete
    def delete
      @collection.delete_one(@query).ok?
    end

    # Count. Returns the number of documents as an integer
    def count
      counter || fetch(:count)
    end

    # Check if there's a corresponding counter for this count
    def counter(s = @store[:source], c = @store[:chain])
      s.send(%{#{@colname}#{c.present? ? "_#{c.join('_')}" : ''}_count}) rescue nil
    end

    # Return first document
    def first(*args)
      modelize(find(*args).fetch(:first))
    end

    # Return last document
    def last(*args)
      sort(:_id => -1).limit(1).first(*args)
    end

    # Return all documents
    def all
      fetch(:to_a).map{|d| modelize(d)}
    end

    # Doc to model
    def modelize(doc)
      doc ? @model.new(doc.to_hash) : nil
    end

    # Paginate
    def paginate(o = {})
      # Get total count before applying pagination
      total = fetch(:count)

      # Set page, defaults to 1
      o[:page] = o[:page].to_i; o[:page] = 1 if o[:page] < 1

      # Set results per page, defaults to 20 in Mongocore.per_page setting
      o[:per_page] = o[:per_page].to_i; o[:per_page] = Mongocore.per_page if o[:per_page] < 1

      # Skip results
      store[:skip] = o[:per_page] * (o[:page] - 1)

      # Apply limit
      store[:limit] = o[:per_page]

      # Fetch the result as array
      fetch(:to_a).map{|d| modelize(d)}.tap{|r| r.total = total}
    end

    # Fetch docs, pass type :first, :to_a or :count
    def fetch(t)
      cache.get(t) if Mongocore.cache

      # Fetch from mongodb and add to cache
      cursor.send(t).tap{|r| cache.set(t, r) if Mongocore.cache}
    end

    # Sort
    def sort(o = {})
      find(@query, @options, @store.tap{store[:sort].merge!(o)})
    end

    # Limit
    def limit(n = 1)
      find(@query, @options, @store.tap{store[:limit] = n})
    end

    # Skip
    def skip(n = 0)
      find(@query, @options, @store.tap{store[:skip] = n})
    end

    # Fields (projection)
    def fields(o = {})
      find(@query, @options, @store.tap{store[:fields].merge!(o)})
    end

    # Cache key
    def key
      @key ||= "#{@model}#{@query.sort}#{@options.sort}#{@store.values}"
    end

    # String id to BSON::ObjectId, or create a new by passing nothing or nil
    def oid(id = nil)
      return id if id.is_a?(BSON::ObjectId)
      return BSON::ObjectId.new if !id
      BSON::ObjectId.from_string(id) rescue id
    end

    # Call and return the scope if it exists
    def method_missing(name, *arguments, &block)
      return @model.send(name, @query, @options, @store.tap{@store[:chain] << name}) if @model.schema.scopes.has_key?(name)
      super
    end

  end
end
