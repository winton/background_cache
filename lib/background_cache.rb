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
      expired_at = ::ActionController::Base.cache_store.read(id).to_i
      # If last expired doesn't exist or is older than :every
      if !expired_at || !cache[:every] || Time.now.to_i - expired_at >= cache[:every].to_i
        # Get URL
        url = cache[:path] || instance.url_for(cache[:params].merge(:only_path => true))
        # Request action with ?background_cache
        instance.get(url + "#{url.include?('?') ? '&' : '?'}background_cache=#{key}")
        # Update last expired time
        ::ActionController::Base.cache_store.write(id, Time.now.to_i)
      end
    end
  end
  def self.set_key!
    key = BackgroundCache::Config.key
    ::ActionController::Base.cache_store.write('background_cache/key', key)
    key
  end
end