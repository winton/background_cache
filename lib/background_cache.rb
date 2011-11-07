require 'rubygems'

require "rack/test"
require "redis"
require "yajl"

require 'digest/sha2'
require 'yaml'

$:.unshift File.dirname(__FILE__)

require 'background_cache/client'
require 'background_cache/config'
require 'background_cache/controller'
require 'background_cache/helper'
require 'background_cache/mem_cache'

module BackgroundCache
  
  class AppInstance
    if defined?(ActionDispatch::Routing::UrlFor)
      include ActionDispatch::Routing::UrlFor
    elsif defined?(ActionController::UrlWriter)
      include ActionController::UrlWriter
    end
    include Rack::Test::Methods
    def app
      if defined?(Rails::Application)
        Rails::Application.subclasses.first
      elsif defined?(ActionController::Dispatcher)
        ActionController::Dispatcher.new
      end
    end
  end
  
  def self.active?
    BackgroundCache::Config.current_cache
  end

  def self.attach!
    ActionController::Base.send(:include, BackgroundCache::Controller)
    ActionView::Helpers::CacheHelper.send(:include, BackgroundCache::Helper)

    ::Dalli::Client.send(:include, BackgroundCache::Memcache)    if defined?(::Dalli::Client)
    ::MemCache.send(:include, BackgroundCache::Memcache)         if defined?(::MemCache)
    ::Memcached::Rails.send(:include, BackgroundCache::Memcache) if defined?(::Memcached::Rails)
  end

  def self.cache!(group=nil, instance=nil)
    unless instance
      instance = self.boot
    end
    BackgroundCache::Config.load!(group)
    caches = BackgroundCache::Config.caches
    caches.each do |cache|
      next if group && cache[:group] != group
      self.manual(cache, instance)
    end
  end

  def self.manual(cache, instance=nil)
    ENV['BACKGROUND_CACHE'] = '1'
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