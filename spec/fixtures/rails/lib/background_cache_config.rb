BackgroundCache::Config.new do
  cache(:path => '/')
  layout(false) do
    only('test_2') do
      cache(
        :controller => 'application',
        :action => 'test_2'
      )
    end
    cache(
      :controller => 'application',
      :action => 'test_3'
    )
  end
end