require "pp"
require "bundler"

Bundler.require(:development)

COMMENT_REGEX = /<!-- .+ cached .+ -->\n/
RAILS_ENV = 'production'

require 'spec/fixtures/rails/config/environment'

$root = File.expand_path('../../', __FILE__)

def cache_read(key)
  value = ::ActionController::Base.cache_store.read('views/' + key)
  value ? value.gsub(COMMENT_REGEX, '') : value
end

def cache_write(key, value)
  ::ActionController::Base.cache_store.write('views/' + key, value)
end