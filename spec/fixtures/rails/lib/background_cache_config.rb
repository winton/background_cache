BackgroundCache::Config.new do |config|
  config.cache(
    :path => '/'
  )
  config.every(1.minute).layout(false).only('test_2') do
    config.cache(
      :controller => 'application',
      :action => 'test_2'
    )
  end
  config.cache(
    :controller => 'application',
    :action => 'test_3'
  )
end