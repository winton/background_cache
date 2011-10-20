BackgroundCache
===============

Bust caches before your users do (in your Rails app).

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
BackgroundCache::Config.new do

  # Configure a background cache in one call
  
  Tag::League.find(:all).each do |tag|
    cache(
      # Route params
      :controller => 'sections',
      :action => 'teams',
      :tag => tag.permalink,
      
      # Background cache options
      :group => 'every_hour',
      :layout => false,
      :only => "sections_teams_#{tag.permalink}"
    )
  end
  
  # Configure using block methods
  
  group('every_hour').layout(false).only("sections_teams_#{tag.permalink}") do
    Tag::League.find(:all).each do |tag|
      cache("/#{tag.permalink}")
    end
  end
end
</pre>

The <code>cache</code> method takes route parameters or a path.

The <code>only</code> and <code>except</code> methods/options take fragment ids or arrays of fragment ids.

If no fragment is specified, all of the action's caches will regenerate.

Rake task
---------

Add <code>rake background_cache</code> to cron. All cache configurations are busted every time it is run.

To run a specific group of caches, run <code>rake background\_cache[every\_hour]</code> (as per the example above).
