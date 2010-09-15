require File.dirname(__FILE__) + "/spec_helper"

describe BackgroundCache do

  include Rack::Test::Methods

  def app
    ActionController::Dispatcher.new
  end
  
  before(:each) do
    BackgroundCache::Config.unload!
  end
  
  describe :Controller do
  
    it "should call load! with background_cache_load parameter" do
      key = BackgroundCache.set_key!
      BackgroundCache::Config.should_receive(:load!)
      get('/', { :background_cache_load => key })
    end
  
    it "should call from_controller with background_cache parameter" do
      key = BackgroundCache.set_key!
      BackgroundCache::Config.should_receive(:from_controller)
      get('/', { :background_cache => key })
    end
    
    it "should alias read_fragment and return null when it is called on matching cache" do
      key = BackgroundCache.set_key!
      get('/', { :background_cache_load => key })
      cache_write('test_3', 'bust me')
      get('/t3', { :background_cache => key })
      last_response.body.should == 'nil'
    end
  end
  
  describe :cache! do
    
    before(:each) do
      ::ActionController::Base.cache_store.clear
    end
    
    describe :test_1 do
    
      it "should be caching normally" do
        get('/')
        cache_read('test').should == 'test'
        cache_write('test', 'bust me')
        get('/')
        cache_read('test').should == 'bust me'
      end
    
      it "should bust the cache" do
        cache_write('test', 'bust me')
        BackgroundCache.cache!
        cache_read('test').should == 'test'
      end
      
      it "should render the layout" do
        BackgroundCache.cache!
        cache_read('layout_test_1').should == '1'
      end
    end
    
    describe :test_2 do
    
      it "should be caching normally" do
        get('/t2')
        cache_read('test_2').should == 'test 2'
        cache_write('test_2', 'bust me')
        get('/t2')
        cache_read('test_2').should == 'bust me'
      end
    
      it "should bust the cache" do
        cache_write('test_2', 'bust me')
        BackgroundCache.cache!
        cache_read('test_2').should == 'test 2'
      end
      
      it "should not bust the excluded cache" do
        cache_write('test_1', 'bust me')
        BackgroundCache.cache!
        cache_read('test_1').should == 'bust me'
      end
      
      it "should not render the layout" do
        BackgroundCache.cache!
        cache_read('layout_test_2').should == nil
      end
    end
  end
end