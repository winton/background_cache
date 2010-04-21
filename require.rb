require 'rubygems'
gem 'require'
require 'require'

Require do
  gem :require, '=0.2.7'
  gem(:'rack-test', '=0.5.3') { require 'rack/test' }
  gem(:rake, '=0.8.7') { require 'rake' }
  gem :rspec, '=1.3.0'
  
  gemspec do
    author 'Winton Welsh'
    dependencies do
      gem :'rack-test'
      gem :require
    end
    email 'mail@wintoni.us'
    name 'background_cache'
    homepage "http://github.com/winton/#{name}"
    summary "Bust caches before your users do"
    version '0.1.0'
  end
  
  bin { require 'lib/background_cache' }
  
  lib do
    gem :'rack-test'
    require 'lib/background_cache/config'
    require 'lib/background_cache/controller'
    require 'lib/background_cache/helper'
  end
  
  rails_init { require 'lib/background_cache' }
  
  rakefile do
    gem(:rake) { require 'rake/gempackagetask' }
    gem(:rspec) { require 'spec/rake/spectask' }
    require 'require/tasks'
  end
  
  spec_helper do
    gem :'rack-test'
    require 'require/spec_helper'
    require 'pp'
    require 'spec/fixtures/rails/config/environment'
  end
end
