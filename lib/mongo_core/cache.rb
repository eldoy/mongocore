module MongoCore
  class Cache

    attr_accessor :query, :type, :key, :cache

    # Uses the MongoDB Ruby driver to query the DB.
    # The cache is using RequestStore as backing
    # @type is :first, :to_a or :count
    # @query is a MongoCore::Query
    def initialize(q, t = :first)
      @query, @type = [q, t]
      @key = %{#{q.cache}-#{t}}
      @cache = (RequestStore[:cache] ||= {})

      # Release this key if store[:cache] is false
      clear if q.store[:cache] == false
    end

    # Find
    def find
      return cache[key] if (MongoCore.caching and cache.has_key?(key))
      .tap{|h| puts (h ? 'Hit' : 'Miss') + ': ' + key if MongoCore.debug}
      query.collection.find(query.query, query.options).sort(query.store[:sort] || {}).
      limit(query.store[:limit] || 0).send(type).
      tap{|r| cache[key] = r if MongoCore.caching}
    end

    # Update
    def update(a)
      query.collection.update_one(query.query, {'$set' => a}, :upsert => true)
    end

    # Delete
    def delete
      query.collection.delete_one(query.query)
    end

    # Remove from cache
    def clear
      cache.delete(key)
    end

  end
end
