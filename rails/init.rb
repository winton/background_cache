begin
  require 'memcache'
rescue LoadError
end

require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.rails_init!

ActionController::Base.send(:include, BackgroundCache::Controller)
ActionView::Helpers::CacheHelper.send(:include, BackgroundCache::Helper)
::MemCache.send(:include, BackgroundCache::Memcache) if defined?(::MemCache)