module Temple
  # Immutable hash class which supports hash merging
  # @api public
  class ImmutableHash
    include Enumerable

    def initialize(*hash)
      @hash = hash.compact
    end

    def include?(key)
      @hash.any? {|h| h.include?(key) }
    end

    def [](key)
      @hash.each {|h| return h[key] if h.include?(key) }
      nil
    end

    def each
      keys.each {|k| yield(k, self[k]) }
    end

    def keys
      @hash.inject([]) {|keys, h| keys += h.keys }.uniq
    end

    def values
      keys.map {|k| self[k] }
    end
  end

  # Mutable hash class which supports hash merging
  # @api public
  class MutableHash < ImmutableHash
    def initialize(*hash)
      super({}, *hash)
    end

    def []=(key, value)
      @hash.first[key] = value
    end

    def update(hash)
      @hash.first.update(hash)
    end
  end
end
