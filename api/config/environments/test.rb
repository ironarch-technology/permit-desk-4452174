Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.active_support.deprecation = :stderr
  config.log_level = :warn
  config.hosts.clear
end
