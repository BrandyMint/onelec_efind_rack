require './efind_app'

require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = '435d4cbfc384e5c750cde1c58746c7f3'
end

use Bugsnag::Rack
use Rack::Reloader if ENV['RACK_ENV'] == 'development'
# use Rack::CommonLogger, Logger.new('log/app.log')

run EfindApp.new
