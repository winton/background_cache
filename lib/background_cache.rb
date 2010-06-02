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
  def self.cache!(group=nil)
    key = set_key!
    # Used to make requests
    instance = AppInstance.new
    # Load the application background cache config (stay dynamic)
    instance.get("/?background_cache_load=#{key}")
    # Retrieve caches from config
    load RAILS_ROOT + "/lib/background_cache_config.rb"
    caches = BackgroundCache::Config.caches
    caches.each do |cache|
      next if group && cache[:group] != group
      # Get URL
      url = cache[:path] || instance.url_for(cache[:params].merge(:only_path => true))
      puts "(#{cache[:group]}) #{url}"
      # Request action with ?background_cache
      instance.get(url + "#{url.include?('?') ? '&' : '?'}background_cache=#{key}")
    end
  end
  def self.manual(url)
    key = set_key!
    instance = AppInstance.new
    url = instance.url_for(url) if url.respond_to?(:keys)
    instance.get(url + "#{url.include?('?') ? '&' : '?'}background_cache=#{key}")
  end
  def self.set_key!
    key = BackgroundCache::Config.key
    ::ActionController::Base.cache_store.write('background_cache/key', key)
    key
  end
end

def BackgroundCache(url)
  BackgroundCache.manual(url)
end