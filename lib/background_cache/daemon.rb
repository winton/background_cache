require 'rubygems'

require "digest/sha1"
require "timeout"
require "yaml"

require "redis"
require "yajl"

module BackgroundCache
  class Daemon

    def initialize(root)
      if File.exists?(yaml = "#{root}/config/background_cache.yml")
        options = YAML.load(File.read(yaml))
      else
        puts "\nFAIL: config/background_cache.yml not found"
        shutdown
      end

      puts "\nStarting background cache server (redis @ #{options['redis']})..."

      require "#{root}/config/environment.rb"
      require File.expand_path("../../background_cache", __FILE__)

      instance = BackgroundCache.boot
      redis = Redis.connect(:url => "redis://#{options['redis']}")
      retries = 0
      
      begin
        while true
          request = redis.lpop('background_cache:request')
          if request
            puts request.inspect
            Timeout.timeout(60) do
              request = Yajl::Parser.parse(request)
              channel = request.delete('channel')

              cache_key = 'background_cache:queue:' + request.to_a.sort { |a, b| a.first <=> b.first }.inspect

              request.keys.each do |key|
                request[(key.to_sym rescue key) || key] = request.delete(key)
              end
              
              unless redis.get(cache_key)
                redis.set(cache_key, 1)

                # Timeout incase execution fails
                redis.expire(cache_key, 5 * 60)

                if request[:group]
                  BackgroundCache.cache!(request[:group], instance)
                else
                  BackgroundCache.manual(
                    BackgroundCache::Config.build_cache(request),
                    instance
                  )
                end

                redis.del(cache_key)
                redis.publish(
                  "background_cache:response:#{channel}",
                  "[SUCCESS]"
                )
              end
            end
          end

          sleep(1.0 / 1000.0)
        end
      rescue Interrupt
        shut_down
      rescue Exception => e
        puts "\nError: #{e.message}"
        puts "\t#{e.backtrace.join("\n\t")}"
        retries += 1
        shut_down if retries >= 10
        retry
      end
    end

    def shut_down
      puts "\nShutting down background cache server..."
      exit
    end
  end
end