desc "Background cache cron job"
task :background_cache, :group, :needs => :environment do |t, args|
  BackgroundCache.cache! args[:group]
end