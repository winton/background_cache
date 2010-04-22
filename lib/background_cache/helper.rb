module BackgroundCache
  module Helper
    def self.included(base)
      base.alias_method_chain :cache, :background_cache
    end
    def cache_with_background_cache(name = {}, options = nil, &block)
      cache = BackgroundCache::Config.from_controller_and_fragment(controller, name)
      if cache
        RAILS_DEFAULT_LOGGER.info "Cached fragment busted (cache block): #{key}"
        # http://api.rubyonrails.org/classes/ActionView/Helpers/CacheHelper.html
        # http://api.rubyonrails.org/classes/ActionController/Caching/Fragments.html
        # ActionController::Caching::Fragments#fragment_for (undocumented)
        pos = output_buffer.length
        block.call
        output = [
          "<!-- #{name} cached #{Time.now.strftime("%m/%d/%Y at %I:%M %p")} -->",
          output_buffer[pos..-1]
        ].join("\n")
        @controller.write_fragment(name, output, options)
      else
        cache_without_background_cache(name, options, &block)
      end
    end
  end
end