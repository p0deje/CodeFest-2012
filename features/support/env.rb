ENV['RAILS_ENV'] = 'cucumber'

require "#{File.dirname(__FILE__)}/../../config/environment"

DOWNLOADS_DIR   = "#{Rails.root}/tmp/tests_downloads"
SAVED_PAGES_DIR = "#{Rails.root}/tmp/pages"
SCREENSHOTS_DIR = "#{Rails.root}/tmp/screenshots"

require 'watir-webdriver'
require 'page-object'
require 'be_valid_asset'
require 'factory_girl_rails'

require 'capybara/rails'
Capybara.configure do |capybara|
  capybara.server_boot_timeout = 30
  capybara.server_port = 9887
  # increment port with TEST_ENV_NUMBER which is an environmental
  # variable supplied by parallel_tests gem
  capybara.server_port += ENV['TEST_ENV_NUMBER'].to_i
end

require 'unicorn'
Capybara.server do |app, port|
  Unicorn::Configurator::RACKUP[:port] = port
  Unicorn::Configurator::RACKUP[:set_listener] = true
  Unicorn::HttpServer.new(app).start
end

require "#{Rails.root}/features/support/cucumber_helper"
include CucumberHelper
Testing.base_url = "http://localhost:#{Capybara.server_port}"

require 'database_cleaner'
TABLES_TO_TRUNCATE = %w(users)
DatabaseCleaner.strategy = :truncation, { only: TABLES_TO_TRUNCATE }
