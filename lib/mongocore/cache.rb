module Mongocore

  # # # # # # # #
  # The Cache class keeps track of cache entries.
  #
  # Every query is cached, used the state as the cache key. This is a
  # very aggressive strategy, where arrays won't get update on update or delete.
  #

  class Cache

    # Accessors
    attr_accessor :query, :cache, :key, :type

    # Init
    def initialize(q)
      @query = q
      @cache = (RequestStore[:cache] ||= {})
      @key = gen(q)
    end

    # Get the cache key
    def get(t)
      @type = t; @cache[f].tap{|d| stat(d)}
    end

    # Set the cache key
    def set(t, v = nil)
      @type = t; v ? @cache[f] = v : @cache.delete(f)
    end

    private

    # Cache key
    def gen(q)
      Digest::MD5.hexdigest("#{q.model}#{q.query.sort}#{q.options.sort}#{q.store[:chain]}#{q.store[:sort]}#{q.store[:cache]}#{q.store[:limit]}")
    end

    # Stats for debug and cache
    def stat(d)
      return unless Mongocore.debug

      # Cache debug
      puts('Cache ' + (d ? 'Hit!' : 'Miss') + ': ' + f)

      # Store hits and misses
      RequestStore[d ? :h : :m] = (RequestStore[d ? :h : :m] || 0) + 1
    end

    # Short cut for full cache key
    def f
      @f ||= "#{@key}-#{@type}"
    end

  end
end
