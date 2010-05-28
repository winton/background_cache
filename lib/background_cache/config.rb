require 'digest/sha2'

module BackgroundCache
  class Config
    def initialize(&block)
      @@caches = []
      yield self
    end
    def cache(options)
      # Method-style config
      @options ||= {}
      options = @options.merge(options)
      # Store the cache options
      @@caches.push({
        :except => options.delete(:except),
        :every => options.delete(:every),
        :group => options.delete(:group),
        :layout => options.delete(:layout),
        :only => options.delete(:only),
        :path => options.delete(:path),
        :params => options
      })
    end
    def except(value, &block)
      set_option(:except, value, &block)
    end
    def every(value, &block)
      set_option(:every, value, &block)
    end
    def group(value, &block)
      set_option(:group, value, &block)
    end
    def layout(value, &block)
      set_option(:layout, value, &block)
    end
    def only(value, &block)
      set_option(:only, value, &block)
    end
    def set_option(key, value, &block)
      @options ||= {}
      @options[key] = value
      if block
        yield
        @options = {}
      end
      self
    end
    # Find cache config from params
    def self.from_controller(controller)
      from_controller_and_fragment(controller)
    end
    def self.from_controller_and_fragment(controller, fragment={})
      params = controller.params
      params.delete 'background_cache'
      path = controller.request.env['REQUEST_URI'].gsub(/[&?]background_cache=.+/, '')
      if defined?(@@caches) && !@@caches.empty?
        @@caches.detect do |item|
          # Basic params match (action, controller, etc)
          (
            (item[:path] && item[:path] == path) ||
            item[:params] == params.symbolize_keys
          ) &&
          (
            # No fragment specified
            fragment.empty? ||
            (
              (
                # :only not defined
                !item[:only] ||
                # :only matches fragment
                item[:only] == fragment ||
                (
                  # :only is an array
                  item[:only].respond_to?(:index) &&
                  # :only includes matching fragment
                  item[:only].include?(fragment)
                )
              ) &&
              (
                # :except not defined
                !item[:except] ||
                # :except not explicitly named
                item[:except] != fragment ||
                (
                  # :except is an array
                  item[:except].respond_to?(:index) &&
                  # :except does not include matching fragment
                  !item[:except].include?(fragment)
                )
              )
            )
          )
        end
      end
    end
    def self.caches
      @@caches
    end
    def self.key
      Digest::SHA256.hexdigest("--#{Time.now}--#{rand}--")
    end
    def self.load!
      load RAILS_ROOT + "/lib/background_cache_config.rb"
    end
    def self.unload!
      @@caches = []
    end
    # Unique cache id for storing last expired time
    def self.unique_cache_id(cache)
      id = []
      join = lambda do |k, v|
        id << (k.nil? || v.nil? ?
          nil : [ k, v ].collect { |kv| kv.to_s.gsub(/\W/, '_') }.join('-')
        )
      end
      cache[:params].each do |key, value|
        join.call(key, value)
      end
      cache.each do |key, value|
        join.call(key, value) unless key == :params
      end
      'background_cache/' + id.compact.join('/')
    end
  end
end