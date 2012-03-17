TopTal::Application.configure do
  config.cache_classes = false
  config.whiny_nils = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = true
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr

  # Tell ActionMailer to cache emails instead of sending them on Cucumber.
  # We can't user :test delivery method because server and webdriver are
  # different processes and do not share ActionMailer::Base.deliveries.
  config.action_mailer.delivery_method = :cache
  # We also need to separate cache files for parallel_tests
  location = "#{Rails.root}/tmp/cache/action_mailer_cache_deliveries#{ENV['TEST_ENV_NUMBER']}.cache"
  config.action_mailer.cache_settings = { location: location }
  # We also need to set corresponding server instance's hostname (only for Cucumber)
  host = defined?(Testing) ? Testing.base_url.gsub(%r(^https?://), '') : 'localhost:3000'
  config.action_mailer.default_url_options = { host: host }
end
