module BackgroundCache
  class Client

    attr_reader :redis_1, :redis_2

    def initialize(root)
      if File.exists?(yaml = "#{root}/config/background_cache.yml")
        options = YAML.load(File.read(yaml))
      else
        puts "\nFAIL: config/background_cache.yml not found"
        shutdown
      end

      @redis_1 = Redis.connect(:url => "redis://#{options['redis']}")
      @redis_2 = Redis.connect(:url => "redis://#{options['redis']}")
    end

    def cache(options)
      wait = options.delete(:wait)
      subscribe_to = options[:channel] = Digest::SHA1.hexdigest("#{rand}")
      options = Yajl::Encoder.encode(options)
      response = nil

      if wait != false
        Timeout.timeout(60) do
          @redis_1.subscribe("background_cache:response:#{subscribe_to}") do |on|
            on.subscribe do |channel, subscriptions|
              @redis_2.rpush "background_cache:request", options
            end

            on.message do |channel, message|
              if message.include?('[SUCCESS]')
                response = true
                @redis_1.unsubscribe
              end
            end
          end
        end
      else
        @redis_1.rpush "background_cache:request", options
      end

      response
    end

    def queued
      queues = @redis_2.keys 'background_cache:queue:*'
      queues.collect do |q|
        queue['background_cache:queue:'.length..-1]
      end
    end
  end
end