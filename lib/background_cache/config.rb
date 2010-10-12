require 'digest/sha2'

module BackgroundCache
  class Config
    
    class <<self
      attr_accessor :current_cache
    end
    
    def initialize(&block)
      @@caches = []
      self.instance_eval &block
    end
    
    def cache(options)
      @options ||= []
      options = @options.inject({}) { |hash, option| hash.merge(option) }.merge(options)
      @@caches << self.class.build_cache(options)
    end
    
    def except(value, &block)
      set_option({ :except => value }, &block)
    end
    
    def group(value, &block)
      set_option({ :group => value }, &block)
    end
    
    def layout(value, &block)
      set_option({ :layout => value }, &block)
    end
    
    def only(value, &block)
      set_option({ :only => value }, &block)
    end
    
    def set_option(hash, &block)
      @options ||= []
      @options << hash
      if block
        @last_option_index ||= []
        @last_option_index << (@options.length - 1)
        yield
        @last_option_index.pop
        if @last_option_index.empty?
          @options = []
        else
          @options = @options[0..@last_option_index.last]
        end
      end
      self
    end
    
    def self.build_cache(options)
      {
        :except => options.delete(:except),
        :group => options.delete(:group),
        :layout => options.delete(:layout),
        :only => options.delete(:only),
        :path => options.delete(:path),
        :params => options
      }
    end
    
    # Does controller and fragment match current cache?
    def self.match?(controller, fragment={})
      params = controller.params
      path = controller.request.env['REQUEST_URI']
      cache = self.current_cache
      cache &&
      # Basic params match (action, controller, etc)
      (
        (cache[:path] && cache[:path] == path) ||
        cache[:params] == params.symbolize_keys
      ) &&
      (
        # No fragment specified
        fragment.empty? ||
        (
          (
            # :only not defined
            !cache[:only] ||
            # :only matches fragment
            cache[:only] == fragment ||
            (
              # :only is an array
              cache[:only].respond_to?(:index) &&
              # :only includes matching fragment
              cache[:only].include?(fragment)
            )
          ) &&
          (
            # :except not defined
            !cache[:except] ||
            # :except not explicitly named
            cache[:except] != fragment ||
            (
              # :except is an array
              cache[:except].respond_to?(:index) &&
              # :except does not include matching fragment
              !cache[:except].include?(fragment)
            )
          )
        )
      )
    end
    
    def self.caches
      defined?(@@caches) ? @@caches : []
    end
    
    def self.load!
      load RAILS_ROOT + "/lib/background_cache_config.rb"
    end
    
    def self.unload!
      @@caches = []
      self.current_cache = nil
    end
  end
end