module BackgroundCache
  module Memcache
    
    def self.included(base)
      base.alias_method_chain :get, :background_cache
      base.alias_method_chain :get_multi, :background_cache
    end

    def get_with_background_cache(key, raw=false)
      match = (
        BackgroundCache.active? &&
        BackgroundCache.match?(key)
      )
      if match
        nil
      else
        get_without_background_cache(key, raw)
      end
    end

    def get_multi_with_background_cache(key, options={})
      match = (
        BackgroundCache.active? &&
        BackgroundCache.match?(key)
      )
      if match
        nil
      else
        get_multi_without_background_cache(key, options)
      end
    end
  end
end