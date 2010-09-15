require 'digest/sha2'

module BackgroundCache
  class Config
    class <<self
      attr_accessor :manual
    end
    def initialize(&block)
      @@caches = []
      self.instance_eval &block
    end
    def cache(options)
      # Method-style config
      @options ||= {}
      options = @options.merge(options)
      # Store the cache options
      @@caches.push({
        :except => options.delete(:except),
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
      cache =
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
      if !cache && self.manual
        cache = { :path => path, :layout => false }
      end
      cache
    end
    def self.caches
      @@caches if defined?(@@caches)
    end
    def self.key
      Digest::SHA256.hexdigest("--#{Time.now}--#{rand}--")
    end
    def self.load!
      load RAILS_ROOT + "/lib/background_cache_config.rb"
    end
    def self.unload!
      @@caches = []
      self.manual = nil
    end
  end
end