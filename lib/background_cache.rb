require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.lib!

module BackgroundCache
  class AppInstance
    include ActionController::UrlWriter
    include Rack::Test::Methods
    def app
      ActionController::Dispatcher.new
    end
  end
  def self.cache!
    key = set_key!
    # Used to make requests
    instance = AppInstance.new
    # Load the application background cache config (stay dynamic)
    instance.get("/?background_cache_load=#{key}")
    # Retrieve caches from config
    load RAILS_ROOT + "/lib/background_cache_config.rb"
    caches = BackgroundCache::Config.caches
    caches.each do |cache|
      # Unique cache id for storing last expired time
      id = BackgroundCache::Config.unique_cache_id(cache)
      # Find out when this cache was last expired
      expired_at = ::ActionController::Base.cache_store.read(id)
      # If last expired doesn't exist or is older than :every
      if !expired_at || Time.now - expired_at > cache[:every]
        # Request action with ?background_cache
        instance.get(instance.url_for(cache[:params]) + "?background_cache=#{key}")
        # Update last expired time
        ::ActionController::Base.cache_store.write(id, Time.now)
      end
      puts id
    end
    # Unload the application background cache config
    instance.get("/?background_cache_unload=#{key}")
  end
  def self.set_key!
    key = BackgroundCache::Config.key
    ::ActionController::Base.cache_store.write('background_cache/key', key)
    key
  end
end