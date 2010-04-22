module BackgroundCache
  module Controller
    def self.included(base)
      base.alias_method_chain :read_fragment, :background_cache
      base.around_filter BackgroundCacheFilter.new
    end
      
    private
    
    def read_fragment_with_background_cache(key, options=nil)
      cache = BackgroundCache::Config.from_params_and_fragment(params, key)
      if cache
        nil
      else
        read_fragment_without_background_cache(key, options)
      end
    end
    
    class BackgroundCacheFilter
      def before(controller)
        @background_cache = {
          :key => controller.params.delete("background_cache"),
          :load => controller.params.delete("background_cache_load"),
          :unload => controller.params.delete("background_cache_unload")
        }
        if @background_cache[:key]
          # Secure filters
          key = ::ActionController::Base.cache_store.read('background_cache/key')
          # Turn off the layout if necessary
          if @background_cache[:key] == key
            cache = BackgroundCache::Config.from_params(controller.params)
            # Store current layout, then disable it
            if cache && cache[:layout] == false
              @background_cache[:layout] = controller.active_layout
              controller.class.layout(false)
            end
          end
        end
        true
      end
      def after(controller)
        # Restore layout
        if @background_cache[:layout]
          controller.class.layout(@background_cache[:layout])
        end
        if @background_cache[:load] || @background_cache[:unload]
          # Secure filters
          key = ::ActionController::Base.cache_store.read('background_cache/key')
          # Load the background cache config
          if @background_cache[:load] == key
            BackgroundCache::Config.load!
          # Unload the background cache config
          elsif @background_cache[:unload] == key
            BackgroundCache::Config.unload!
          end
        end
      end
    end
  end
end