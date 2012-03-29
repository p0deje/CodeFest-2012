source 'http://rubygems.org'

# use unicorn as the web server
gem 'unicorn', '4.1.1'

group :test, :cucumber do
  gem 'cucumber'                    , '1.1.8'  # front-end for functional tests
  gem 'capybara'                    , '1.1.2'  # use Capybara to start server
  gem 'syntax'                      , '1.0.0'  # syntax highlighting in Cucumber HTML reports
  gem 'watir-webdriver'             , '0.5.3'  # back-end for functional tests
  gem 'page-object'                 , '0.6.2'  # painless creation of page objects
  gem 'be_valid_asset'              , '1.1.2'  # validate HTML code against W3C
  gem 'factory_girl_rails'          , '1.7.0'  # replacement to fixtures
  gem 'database_cleaner'            , '0.7.1'  # clean database after tests
  gem 'ci_reporter'                 , '1.7.0'  # JUnit reports for RSpec
  gem 'parallel_tests'              , '0.6.19' # run tests in parallel
  gem 'action_mailer_cache_delivery', '0.3.2'  # emails testing
end
