BackgroundCache
===============

Bust caches before your users do (in Rails).

Requirements
------------

<pre>
sudo gem install background_cache
</pre>

### config/environment.rb

<pre>
config.gem 'background_cache'
</pre>

Dynamic Configuration
---------------------

Create *lib/background\_cache\_config.rb*:

<pre>
BackgroundCache::Config.new do |config|

  # Configure a background cache in one call
  Tag::League.find(:all).each do |tag|
    config.cache(
      # Route params
      :controller => 'sections',
      :action => 'teams',
      :tag => tag.permalink,
      # Background cache options
      :every => 1.hour,
      :layout => false,
      :only => "sections_teams_#{tag.permalink}"
    )
  end
  
  # Group configure using block methods
  config.every(1.hour).layout(false).only("sections_teams_#{tag.permalink}") do
    Tag::League.find(:all).each do |tag|
      config.cache(
        :controller => 'sections',
        :action => 'teams',
        :tag => tag.permalink
      )
    end
  end
  
  # Or use a mix of the two
end
</pre>

The :only and :except options can be fragment ids or arrays of fragment ids.

If no fragment is specified, all of the action's caches will regenerate.

This configuration reloads every time the rake task runs. New records get background cached.

Rake task
---------

Add <code>rake background_cache</code> to cron. Set the job's duration the same as your shortest cache.

What does the rake task do?

* Adds a security key to memcache that is shared by the app and rake task
* Sends a request to the app to reload its BackgroundCache config
* If time for a cache to expire, the task sends an expire request to the action
* BackgroundCache detects the request within the app and modifies the layout or expiry as configured

Memcached is employed to track the expire time of each background cache. As a side benefit, if memcached restarts, the rake task knows to generate all caches.

Todo
----

* Specs