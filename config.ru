require './efind_app'
require 'pg'
require 'active_support/core_ext/string'

use Rack::Reloader
$conn = PG.connect( dbname: 'onelec_production_2017' )

run EfindApp.new
