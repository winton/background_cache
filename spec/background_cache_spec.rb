require File.dirname(__FILE__) + "/spec_helper"

describe BackgroundCache do

  include Rack::Test::Methods

  def app
    ActionController::Dispatcher.new
  end
  
  describe :Controller do
  
    it "should use our version of the cache method" do
      BackgroundCache::Config.should_receive(:from_params_and_fragment)
      get('/')
    end
  
    it "should call load! with background_cache_load parameter" do
      key = BackgroundCache.set_key!
      BackgroundCache::Config.should_receive(:load!)
      get('/', { :background_cache_load => key })
    end
  
    it "should call unload! with background_cache_unload parameter" do
      key = BackgroundCache.set_key!
      BackgroundCache::Config.should_receive(:unload!)
      get('/', { :background_cache_unload => key })
    end
  
    it "should call from_params with background_cache parameter" do
      key = BackgroundCache.set_key!
      BackgroundCache::Config.should_receive(:from_params)
      get('/', { :background_cache => key })
    end
  end
  
  describe :cache! do
    
    before(:each) do
      ::ActionController::Base.cache_store.delete('views/layout_rendered')
      ::ActionController::Base.cache_store.delete('views/test')
      ::ActionController::Base.cache_store.delete('views/test_2')
    end
    
    it "should be caching normally" do
      get('/')
      ::ActionController::Base.cache_store.read('views/test').should == 'test'
      ::ActionController::Base.cache_store.write('views/test', 'bust me')
      get('/')
      ::ActionController::Base.cache_store.read('views/test').should == 'bust me'
    end
    
    it "should bust the cache" do
      ::ActionController::Base.cache_store.write('views/test', 'bust me')
      BackgroundCache.cache!
      ::ActionController::Base.cache_store.read('views/test').should == 'test'
    end
  end
end