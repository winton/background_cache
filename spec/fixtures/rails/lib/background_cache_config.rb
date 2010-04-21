BackgroundCache::Config.new do |config|
  config.cache(
    :controller => 'application',
    :action => 'test_1',
    :every => 1.minute,
    :layout => false,
    :only => 'test'
  )
end