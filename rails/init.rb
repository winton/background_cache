require File.expand_path('../../lib/background_cache.rb', __FILE__)

ActionController::Base.send(:include, BackgroundCache::Controller)
ActionView::Helpers::CacheHelper.send(:include, BackgroundCache::Helper)

::Dalli::Client.send(:include, BackgroundCache::Memcache)    if defined?(::Dalli::Client)
::MemCache.send(:include, BackgroundCache::Memcache)         if defined?(::MemCache)
::Memcached::Rails.send(:include, BackgroundCache::Memcache) if defined?(::Memcached::Rails)