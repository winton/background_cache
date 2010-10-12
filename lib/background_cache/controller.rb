module BackgroundCache
  module Controller
    
    def self.included(base)
      base.alias_method_chain :read_fragment, :background_cache
      base.around_filter BackgroundCacheFilter.new
    end
      
    private
    
    def read_fragment_with_background_cache(key, options=nil)
      if BackgroundCache.active? && BackgroundCache.match?(self, key)
        RAILS_DEFAULT_LOGGER.info "Cached fragment busted (read_fragment method): #{key}"
        nil
      else
        read_fragment_without_background_cache(key, options)
      end
    end
    
    class BackgroundCacheFilter
      
      def before(controller)
        cache = BackgroundCache::Config.current_cache
        if cache
          if cache[:layout] == false
            @background_cache_layout = controller.active_layout
            controller.class.layout(false)
          else
            @background_cache_layout = nil
          end
        end
        true
      end
      
      def after(controller)
        if @background_cache_layout
          controller.class.layout(@background_cache_layout)
        end
      end
    end
  end
end