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
    instance = boot
    caches = BackgroundCache::Config.caches
    caches.each do |cache|
      next if group && cache[:group] != group
      url = cache[:path] || instance.url_for(cache[:params].merge(:only_path => true))
      puts "(#{cache[:group]}) #{url}"
      instance.get(url)
    end
  end
  
  def self.manual(url)
    instance = boot
    BackgroundCache::Config.manual = true
    url = instance.url_for(url.merge(:only_path => true)) if url.respond_to?(:keys)
    instance.get(url)
    url
  end
  
  private
  
  def self.boot
    instance = AppInstance.new
    BackgroundCache::Config.load!
    instance
  end
end

def BackgroundCache(url)
  BackgroundCache.manual(url)
end