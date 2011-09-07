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
  
  def self.active?
    BackgroundCache::Config.current_cache
  end

  def self.cache!(group=nil)
    instance = self.boot
    BackgroundCache::Config.load!(group)
    caches = BackgroundCache::Config.caches
    caches.each do |cache|
      next if group && cache[:group] != group
      self.manual(cache, instance)
    end
  end

  def self.manual(cache, instance=nil)
    unless instance
      instance = self.boot
    end
    BackgroundCache::Config.current_cache = cache
    url = cache[:path] || instance.url_for(cache[:params].merge(:only_path => true))
    puts "(#{cache[:group]}) #{url}"
    instance.get(url)
    BackgroundCache::Config.current_cache = nil
    url
  end
  
  def self.match?(fragment={})
    BackgroundCache::Config.match?(fragment)
  end

  private

  def self.boot
    instance = AppInstance.new
    instance
  end
end

def BackgroundCache(path, layout=false)
  BackgroundCache.manual(
    BackgroundCache::Config.build_cache(
      path.respond_to?(:keys) ? path : { :path => path, :layout => layout }
    )
  )
end