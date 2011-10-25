# -*- encoding: utf-8 -*-
root = File.expand_path('../', __FILE__)
lib = "#{root}/lib"

$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "background_cache"
  s.version     = '0.2.3'
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ "Winton Welsh" ]
  s.email       = [ "mail@wintoni.us" ]
  s.homepage    = "http://github.com/winton/background_cache"
  s.summary     = %q{Bust caches before your users do}
  s.description = %q{Bust caches before your users do.}

  s.executables = `cd #{root} && git ls-files bin/*`.split("\n").collect { |f| File.basename(f) }
  s.files = `cd #{root} && git ls-files`.split("\n")
  s.require_paths = %w(lib)
  s.test_files = `cd #{root} && git ls-files -- {features,test,spec}/*`.split("\n")

  s.add_development_dependency "rails", "= 2.3.10"
  s.add_development_dependency "rspec", "~> 1.0"

  s.add_dependency "rack-test"
  s.add_dependency "redis"
  s.add_dependency "yajl-ruby"
end