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

      # Storing query and options
      s[:chain] ||= []; s[:source] ||= nil; s[:sort] ||= Mongocore.sort; s[:projection] ||= {}; s[:skip] ||= 0; s[:limit] ||= 0
      @query, @options, @store = @model.schema.ids(hashify(q)), o, s

      # Set up cache
      @cache = Mongocore::Cache.new(self)
    end

    # Find. Returns a Mongocore::Query
    def find(q = {}, o = {}, s = {})
      self.class.new(@model, @query.merge(hashify(q)), @options.merge(o), @store.merge(s))
    end
    alias_method :where, :find

    # Convert string query to hash
    def hashify(q)
      q.is_a?(Hash) ? q : {:_id => q}
    end

    # Cursor
    def cursor
      c = @collection.find(@query, @options)
      c = c.projection(@store[:projection]) if @store[:projection].any?
      c = c.skip(@store[:skip]) if @store[:skip] > 0
      c = c.limit(@store[:limit]) if @store[:limit] > 0
      c = c.sort(@store[:sort]) if @store[:sort].any?
      c
    end

    # Insert
    def insert(a)
      @collection.insert_one(a.delete_if{|k, v| v.nil?})
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
    # Uses the opposite of the Mongocore.sort setting
    def last(*args)
      a = Mongocore.sort.any? ? Mongocore.sort.dup : {:_id => 1}
      sort(a.each{|k, v| a[k] = v * -1}).limit(1).first(*args)
    end

    # Return all documents
    def all
      fetch(:to_a).map{|d| modelize(d)}
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
      @store[:skip] = o[:per_page] * (o[:page] - 1)

      # Apply limit
      @store[:limit] = o[:per_page]

      # Fetch the result as array
      all.tap{|r| r.total = total}
    end

    # BSON::Document to model
    def modelize(doc)
      doc ? @model.new(doc.to_hash) : nil
    end

    # Fetch docs, pass type :first, :to_a or :count
    def fetch(t)
      cache.get(t) if Mongocore.cache

      # Fetch from mongodb and add to cache
      cursor.send(t).tap{|r| cache.set(t, r) if Mongocore.cache}
    end

    # Each
    def each(&block)
      cursor.each{|r| yield(modelize(r))}
    end

    # Each with index
    def each_with_index(&block)
      cursor.each_with_index{|r, n| yield(modelize(r), n)}
    end

    # Each with object
    def each_with_object(obj, &block)
      cursor.each_with_object(obj){|r, o| yield(modelize(r), o)}
    end

    # Map
    def map(&block)
      cursor.map{|r| yield(modelize(r))}
    end

    # Sort
    def sort(o = {})
      find(@query, @options, @store.tap{(store[:sort] ||= {}).merge!(o)})
    end

    # Limit
    def limit(n = 1)
      find(@query, @options, @store.tap{store[:limit] = n})
    end

    # Skip
    def skip(n = 0)
      find(@query, @options, @store.tap{store[:skip] = n})
    end

    # Projection
    def projection(o = {})
      find(@query, @options, @store.tap{store[:projection].merge!(o)})
    end
    alias_method :fields, :projection

    # JSON format
    def as_json(o = {})
      all
    end

    # Cache key
    def key
      @key ||= "#{@model}#{@query.sort}#{@options.sort}#{@store.values}"
    end

    # Call and return the scope if it exists
    def method_missing(name, *arguments, &block)
      return @model.send(name, @query, @options, @store.tap{|r| r[:chain] << name}) if @model.schema.scopes.has_key?(name)
      super
    end

  end
end
