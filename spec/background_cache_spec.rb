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
  
    it "should call from_params with background_cache parameter" do
      key = BackgroundCache.set_key!
      BackgroundCache::Config.should_receive(:from_params)
      get('/', { :background_cache => key })
    end
    
    it "should alias read_fragment and return null when it is called on matching cache" do
      key = BackgroundCache.set_key!
      get('/', { :background_cache_load => key })
      ::ActionController::Base.cache_store.write('views/test_3', 'bust me')
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
      
      it "should render the layout" do
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/layout_test_1').should == '1'
      end
    end
    
    describe :test_2 do
    
      it "should be caching normally" do
        get('/t2')
        ::ActionController::Base.cache_store.read('views/test_2').should == 'test 2'
        ::ActionController::Base.cache_store.write('views/test_2', 'bust me')
        get('/t2')
        ::ActionController::Base.cache_store.read('views/test_2').should == 'bust me'
      end
    
      it "should bust the cache" do
        ::ActionController::Base.cache_store.write('views/test_2', 'bust me')
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/test_2').should == 'test 2'
      end
      
      it "should not bust the excluded cache" do
        ::ActionController::Base.cache_store.write('views/test_1', 'bust me')
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/test_1').should == 'bust me'
      end
      
      it "should not render the layout" do
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/layout_test_2').should == nil
      end
      
      it "should not bust the cache until a minute later" do
        ::ActionController::Base.cache_store.write('views/test_2', 'bust me')
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/test_2').should == 'test 2'
        ::ActionController::Base.cache_store.write('views/test_2', 'bust me')
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/test_2').should == 'bust me'
        time_now = Time.now
        Time.stub!(:now).and_return(time_now + 1.minute)
        BackgroundCache.cache!
        ::ActionController::Base.cache_store.read('views/test_2').should == 'test 2'
      end
    end
  end
end