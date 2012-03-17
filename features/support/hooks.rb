#
# Starts Rails app server.
#
Capybara::Server.new(Capybara.app).boot

#
# Just starts WebDriver and opens homepage.
#
Testing.browser = CucumberHelper.initialize_webdriver
Testing.browser.goto(Testing.base_url)

#
# The hook is called before each scenario.
#
Before do
  # add timestamp as a random variable
  Testing.timestamp = Time.now.to_i

  # connect to db and clean it to avoid seeds collisions
  DatabaseCleaner.start
  DatabaseCleaner.clean

  # clear browser
  Testing.browser = reset_browser

  # initialize empty users hash
  Testing.users = Hash.new

  # initialize empty array for HTML validation errors
  Testing.html_errors = Array.new
end

#
# The hook is called after each scenario.
#
After do |scenario|
  # clear emails cache
  ActionMailer::Base.clear_cache

  # save a screenshot of the failing scenario
  save_screenshot(scenario) if scenario.failed?

  # verify there were no HTML validation errors
  Testing.html_errors.uniq.should be_empty
end

#
# Exits WebDriver when finished.
#
at_exit do
  Testing.browser.close
end

#
# HTML validations.
#
if ENV['w3c_validate']
  include BeValidAsset

  AfterStep { validate_html }
end

#
# Save pages for CSS cleanup.
#
if ENV['save_pages']
  AfterStep { save_pages }
end
