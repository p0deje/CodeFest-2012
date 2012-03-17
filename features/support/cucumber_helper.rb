#
# Global accessors for essential acceptance testing variables.
#
module Testing
  class << self
    attr_accessor :browser     , # WebDriver instance
                  :timestamp   , # random variable
                  :users       , # array of users
                  :base_url    , # base url of system under tests
                  :html_errors   # array of HTML validation errors
  end # << self
end # AcceptanceTesting


#
# Different useful methods for Cucumber tests.
#
module CucumberHelper
  #
  # Initializes WebDriver instance.
  #
  def self.initialize_webdriver
    # prepare Firefox profile
    profile = Selenium::WebDriver::Firefox::Profile.new
    # automatically save pdf files
    profile['browser.download.dir'] = DOWNLOADS_DIR
    profile['browser.download.folderList'] = 2
    profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/pdf'

    # specified TEST_ENV_NUMBER (even empty) means that we use
    # parallel_tests gem and need to use Selenium Grid
    if ENV['TEST_ENV_NUMBER']
      # increase timeout
      http_client = Selenium::WebDriver::Remote::Http::Default.new
      http_client.timeout = 120
      # prepare configuration for Selenium Grid
      capability = Selenium::WebDriver::Remote::Capabilities.firefox
      capability.firefox_profile = profile
      # initialize driver
      driver = Selenium::WebDriver.for(:remote, desired_capabilities: capability, http_client: http_client)
    else
      # initialize driver
      driver = Selenium::WebDriver.for(:firefox, profile: profile)
    end

    # start browser
    browser = Watir::Browser.new(driver)

    # additional waiting for Ajax
    browser.driver.manage.timeouts.implicit_wait = 3

    browser
  end

  #
  # Clears cookies, so we don't need to restart the browser
  # after each test scenario.
  #
  def reset_browser
    # clear cookies
    Testing.browser.cookies.clear

    # open homepage
    unless Testing.browser.url == "/#{Testing.base_url}"
      Testing.browser.goto(Testing.base_url)
    end

    # delete sessions from app
    FileUtils.rm_rf('tmp/sessions')

    Testing.browser
  end

  #
  # Saves page as HTML files.
  #
  def save_pages
    path = SAVED_PAGES_DIR

    # prepare dir
    FileUtils.mkdir(path) unless File.directory?(path)

    # prepare filename
    url = @page.current_url
    url = url.sub(/#{Regexp.quote(Testing.base_url)}\//, '') # remove base url
    url = url.gsub(/\//, '_') # change / to _
    url = 'homepage' if url.empty? # that's homepage left
    filename = "#{path}/#{url}.html"

    # save page
    File.open(filename, 'w') { |f| f.write(@page.html) }
    puts "Saved page to #{filename}"
  end

  #
  # Performs W3C validations on page.
  #
  def validate_html
    @page.html.should be_valid_xhtml
  rescue RSpec::Expectations::ExpectationNotMetError
    # add exception to AcceptanceTesting.html_errors
    # which will be asserted in After hook
    Testing.html_errors << $!
  end

  #
  # Saves screenshot of the page.
  #
  def save_screenshot(scenario)
    path = SCREENSHOTS_DIR

    # prepare dir
    FileUtils.mkdir(path) unless File.directory?(path)

    # prepare scenario name
    if scenario.instance_of?(Cucumber::Ast::OutlineTable::ExampleRow)
      scenario_name = scenario.scenario_outline.name.gsub(/[^\w\-]/, ' ')
      scenario_name << "-Example#{scenario.name.gsub(/\s*\|\s*/, '-')}".chop
    else
      scenario_name = scenario.name.gsub(/[^\w\-]/, ' ')
    end

    # prepare filename
    filename = "#{path}/#{scenario_name}.png"

    # save screenshot
    Testing.browser.driver.save_screenshot(filename)

    # embed into HTML output
    embed(filename, 'image/png')
  end

  #
  # Returns true if file with name was found in download path.
  #
  def downloaded_file?(name)
    begin
      true if check_for_downloaded_file(name)
    rescue Errno::ENOENT
      false
    ensure
      FileUtils.rm_rf(DOWNLOADS_DIR)
    end
  end

  #
  # Yields opened file and ensures downloads directory is removed after.
  #
  def downloaded_file(name)
    begin
      file = File.open(check_for_downloaded_file(name))
      yield file if block_given?
      file.close
    ensure
      FileUtils.rm_rf(DOWNLOADS_DIR)
    end
  end

  #
  # Returns user or creates new one by given role (non-default).
  #
  # Optional arguments are passed to factory.
  #
  def get_user(role, *args)
    # prepare role name
    role = role.parameterize(?_).to_sym unless role.is_a?(Symbol)

    if Testing.users[role]
      # reload user
      Testing.users[role].user.reload
    else
      # create user
      Testing.users[role] = Factory(role, *args)
    end

    Testing.users[role]
  end

  #
  # Returns full name of user by his role.
  #
  def get_user_name(role)
    get_user(role).full_name
  end

  #
  # Returns email of user by his role.
  #
  def get_user_email(role)
    get_user(role).email
  end

  #
  # Returns user ID.
  #
  def get_user_id(role)
    get_user(role).user.id
  end

  #
  # Saves user with role and email into Testing#users hash.
  #
  def save_user(role, email)
    # prepare role name
    role = role.parameterize(?_).to_sym unless role.is_a?(Symbol)

    # make sure no user with same email is saved
    unless get_user(role).email == email
      Testing.users[role] = User.find_by_email(email)
    end
  end

  #
  # Returns an array of emails.
  # Each email is an instance of Mail.
  #
  def emails
    ActionMailer::Base.cached_deliveries
  end

  #
  # Calls block for email.
  #
  # If no options were passed, uses last email.
  #
  def open_email(opts = {}, &blk)
    opts.empty? ? blk.call(emails.last) : blk.call(find_email(opts))
  end

  #
  # Calls block for an array of email.
  #
  def open_emails(opts, &blk)
    blk.call(find_emails(opts))
  end

  #
  # Extracts link from email body.
  #
  # If no links were found in email body, raises exception.
  #
  def extract_link(mail)
    mail.decode_body =~ /<a href="(.+)">/
    $1 or raise "No links in the email."
  end

  #
  # Returns parsed version of human-readable date.
  #
  # Generally, we use "%b, %d %Y" format for date, so it' default.
  #
  def parse_date(date, format = '%b, %d %Y')
    date.to_time.strftime(format)
  end

  private

  #
  # Returns filename (with path) of downloaded file by part of its title.
  #
  # Note, that as long as filename may contain unpredictable set of characters,
  # method requires passing filename argument to be a regular expression.
  #
  def check_for_downloaded_file(name)
    unless name.is_a?(Regexp)
      raise "#downloaded_file accepts only Regexp, but you passed #{name.class}."
    end

    # we need to wait some time to let file be downloaded
    # this only means that file is created, not that it's downloaded completely
    # so checking for its MIME type may fail
    10.times do
      files = Dir["#{DOWNLOADS_DIR}/*"]
      files.each { |f| return f if f =~ name }
      sleep(1)
    end

    raise Errno::ENOENT, "File '#{name}' was not found downloaded."
  end

  #
  # Returns email which matches options.
  #
  def find_email(opts)
    find_emails(opts).first
  end

  #
  # Returns an array of emails which match options.
  #
  # Possible options are :to and :subject.
  #
  # Please note that it searches from the most recent to oldest emails.
  #
  def find_emails(opts)
    emails.reverse.select do |email|
      email.to.include?(opts[:to]) || email.subject == opts[:subject]
    end
  end
end # CucumberHelper
