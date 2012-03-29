ENV['RAILS_ENV'] = 'cucumber'

require 'watir-webdriver'
require 'page-object'
require 'factory_girl_rails'
require 'be_valid_asset' if ENV['w3c_validate']

# Configure Capybara server startup
require 'capybara'
Capybara.configure do |capybara|
  capybara.server_boot_timeout = 30
  capybara.server_port = 9887
  # increment port with TEST_ENV_NUMBER which is an environmental
  # variable supplied by parallel_tests gem
  capybara.server_port += ENV['TEST_ENV_NUMBER'].to_i
end

# Initialize Testing structure and prepare it
require_relative 'cucumber_helper'
include CucumberHelper
Testing.base_url = "http://localhost:#{Capybara.server_port}"

# Initialize application
require_relative '../../config/environment'

# Force Capybara to use Rails app and unicorn
require 'capybara/rails'
require 'unicorn'
Capybara.server do |app, port|
  Unicorn::Configurator::RACKUP[:port] = port
  Unicorn::Configurator::RACKUP[:set_listener] = true
  Unicorn::HttpServer.new(app).start
end

# Initialize directories in use
DOWNLOADS_DIR   = "#{Rails.root}/tmp/downloads"
SAVED_PAGES_DIR = "#{Rails.root}/tmp/pages"
SCREENSHOTS_DIR = "#{Rails.root}/tmp/screenshots"

# Configure database cleaning strategy
require 'database_cleaner'
TABLES_TO_TRUNCATE = %w(users)
DatabaseCleaner.strategy = :truncation, { only: TABLES_TO_TRUNCATE }
