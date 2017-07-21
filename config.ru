require './efind_app'

use Rack::Reloader
# use Rack::CommonLogger, Logger.new('log/app.log')

run EfindApp.new
