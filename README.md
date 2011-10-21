BackgroundCache
===============

Bust caches before your users do (in your Rails app).

Requirements
------------

    gem install background_cache

Dynamic Configuration
---------------------

Create *lib/background\_cache\_config.rb* in your Rails app:

    BackgroundCache::Config.new do

      # Configure using block methods
      
      group('every_hour').layout(false).only("sections_teams_#{tag.permalink}") do
        Tag::League.find(:all).each do |tag|
          cache(:path => "/#{tag.permalink}")
        end
      end

      # Configure using options
      
      Tag::League.find(:all).each do |tag|
        cache(
          # Route params
          :controller => 'sections',
          :action => 'teams',
          :tag => tag.permalink,

          # Or specify a path
          :path => "/#{tag.permalink}",
          
          # Background cache options
          :group => 'every_hour',
          :layout => false,
          :only => "sections_teams_#{tag.permalink}"
        )
      end
    end

The `only` and `except` options take cache fragment ids or arrays of cache fragment ids.

If no fragment is specified, all of the action's caches will regenerate.

Rake Task
---------

Add `rake background_cache` to cron. All cache configurations are busted every time it is run.

To run a specific group of caches, run `rake background_cache[every_hour]` (as per the example above).

Daemon Mode
-----------

Create `config/background_cache.yml` in your Rails app:

    redis: localhost:6379/0

Start a `background_cache` daemon from your Rails app:

    $ cd path/to/app
    $ background_cache

Run caches via Ruby:

    require 'background_cache'

    client = BackgroundCache::Client.new('/path/to/app/config/background_cache.yml')

    # Cache group
    client.cache(:every_hour)

    # Manual cache
    client.cache(:path => "/")