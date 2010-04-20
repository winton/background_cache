desc "Background cache cron job"
task :background_cache => :environment do
  BackgroundCache.cache!
end