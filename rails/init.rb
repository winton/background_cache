begin
  require 'memcache'
rescue LoadError
end

require File.expand_path('../../lib/background_cache.rb', __FILE__)

ActionController::Base.send(:include, BackgroundCache::Controller)
ActionView::Helpers::CacheHelper.send(:include, BackgroundCache::Helper)
::MemCache.send(:include, BackgroundCache::Memcache) if defined?(::MemCache)