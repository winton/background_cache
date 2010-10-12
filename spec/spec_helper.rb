RAILS_ENV = 'production'

require File.expand_path("#{File.dirname(__FILE__)}/../require")
Require.spec_helper!

Spec::Runner.configure do |config|
end

COMMENT_REGEX = /<!-- .+ cached .+ -->\n/

def cache_read(key)
  value = ::ActionController::Base.cache_store.read('views/' + key)
  value ? value.gsub(COMMENT_REGEX, '') : value
end

def cache_write(key, value)
  ::ActionController::Base.cache_store.write('views/' + key, value)
end