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
  
    it "should call load! when cache! called" do
      BackgroundCache::Config.should_receive(:load!)
      BackgroundCache.cache!
    end
    
    it "should alias read_fragment and return null when it is called on matching cache" do
      BackgroundCache.cache!
      BackgroundCache::Config.current_cache = BackgroundCache::Config.caches.detect do |cache|
        cache[:params][:action] == 'test_3'
      end
      cache_write('test_3', 'bust me')
      get('/t3')
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
    
    describe :test_1b do
    
      it "should be caching normally" do
        get('/')
        cache_read('test').should == 'test'
        cache_write('test', 'bust me')
        get('/')
        cache_read('test').should == 'bust me'
      end
    
      it "should bust the cache (manual override)" do
        cache_write('test', 'bust me')
        BackgroundCache('/b')
        cache_read('test').should == 'test'
      end
      
      it "should not render the layout" do
        BackgroundCache('/b')
        cache_read('layout_test_1').should == nil
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
    
    describe :test_3 do
    
      it "should be caching normally" do
        get('/t3')
        cache_read('layout_test_3').should == '1'
        cache_write('layout_test_3', 'bust me')
        get('/t3')
        cache_read('layout_test_3').should == 'bust me'
      end
      
      it "should not render the layout" do
        BackgroundCache.cache!
        cache_read('layout_test_3').should == nil
      end
    end
  end
end