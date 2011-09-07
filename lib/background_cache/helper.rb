module BackgroundCache
  module Helper
    
    def self.included(base)
      base.alias_method_chain :cache, :background_cache
    end
    
    def cache_with_background_cache(name = {}, options = nil, &block)
      # http://railsapi.com/doc/rails-v2.3.8/classes/ActionView/Helpers/CacheHelper.html
      # ActionController::Caching::Fragments#fragment_for (undocumented)
      #   actionpack/lib/action_controller/caching/fragments.rb
      if @controller.perform_caching
        cache = @controller.read_fragment(name, options)
        match = (
          BackgroundCache.active? &&
          BackgroundCache.match?(name)
        )
        if !cache || match
          pos = output_buffer.length
          block.call
          output = [
            "<!-- #{name.inspect}#{' background' if match} cached #{Time.now.strftime("%m/%d/%Y at %I:%M %p")} -->",
            output_buffer[pos..-1]
          ].join("\n")
          @controller.write_fragment(name, output, options)
        else
          output_buffer.concat(cache)
        end
      else
        block.call
      end
    end
  end
end