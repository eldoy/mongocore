module MongoCore
  class Cache
    # Init cache store
    RequestStore.store[:cache] = {}

    # The main find method.
    # @query is a MongoCore::Query
    # @type is :first, :to_a or :count
    # Uses the MongoDB Ruby driver to query the DB.
    def self.find(q, type)
      if MongoCore.caching
        key = %{#{q.cache}-#{type}}
        cached = RequestStore.store[:cache][key]
        if cached
          puts "CACHED!: #{key}" if MongoCore.debug
          return cached
        else
          puts "NOT CACHED: #{key}" if MongoCore.debug
        end
      end
      r = q.collection.find(q.query, q.options).sort(q.store[:sort] || {}).limit(q.store[:limit] || 0).send(type)
      RequestStore.store[:cache][key] = r if MongoCore.caching
      r
    end

    # Update
    def self.update(q, a)
      clear(q)
      q.collection.update_one(q.query, {'$set' => a}, :upsert => true)
    end

    # Delete
    def self.delete(q)
      clear(q)
      q.collection.delete_one(q.query)
    end

    private

    # Remove from cache
    def self.clear(q)
      key = %{#{q.cache}-first}
      RequestStore.store[:cache][key] = nil
    end

  end
end
