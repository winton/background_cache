module BackgroundCache
  module Controller
    
    def self.included(base)
      base.alias_method_chain :read_fragment, :background_cache
      base.alias_method_chain :render, :background_cache
      base.around_filter BackgroundCacheFilter.new
    end
      
    private
    
    def read_fragment_with_background_cache(key, options=nil)
      if BackgroundCache.active? && BackgroundCache.match?(key)
        Rails.logger.info "Cached fragment busted (read_fragment method): #{key}"
        nil
      else
        read_fragment_without_background_cache(key, options)
      end
    end
    
    def render_with_background_cache(options = nil, extra_options = {}, &block)
      if BackgroundCache.active? && BackgroundCache::Config.current_cache[:layout] == false
        [ options, extra_options ].each do |opts|
          if opts.respond_to?(:keys) && (opts[:layout] || opts['layout'])
            opts[opts[:layout] ? :layout : 'layout'] = false
          end
        end
      end
      render_without_background_cache(options, extra_options, &block)
    end
    
    class BackgroundCacheFilter
      
      def before(controller)
        cache = BackgroundCache::Config.current_cache
        if cache
          if cache[:layout] == false
            if controller.respond_to?(:active_layout)
              @background_cache_layout = controller.active_layout
            else
              @background_cache_layout = controller.send :_layout
            end
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