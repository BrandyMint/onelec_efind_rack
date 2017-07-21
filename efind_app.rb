require 'pry'
require 'logger'
require 'pg'
require 'active_support/core_ext/string'
require 'active_record'

class EfindApp
  def initialize
    @error_logger =  Logger.new('log/app_errors.log')

    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml')))
  end

  def call(env)
    req = Rack::Request.new(env)
    query = req.params["search"].to_s.gsub(/[^[:alnum:]\s]/, '').squish.gsub(' ', '&')

    data = query.present? ? fetch_results(query) : []
    response = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><data>"
    response << data.join('')
    response << '</data>'
    [200, {"Content-Type" => "application/xml"}, [response]]
  end

  private

  def fetch_results(query)
    begin
      sql = "SELECT efind_xml FROM \"product_efind_entities\" WHERE #{ts_query(query)} ORDER BY #{ts_rank(query)} desc LIMIT 20"

      ActiveRecord::Base.connection.select_values sql
    rescue => e
      @error_logger << "Time:#{Time.now}\nquery: #{query}\nmessage:#{e.message}\n#{e.backtrace.join("\n")}\n"

      []
    end
  end

  def ts_query(query)
    "(to_tsvector('simple', product_efind_entities.name_ts) @@ to_tsquery('simple', '#{query}:*'))"
  end

  def ts_rank(query)
    "ts_rank_cd(to_tsvector('simple', name_ts), to_tsquery('simple', '#{query}'))"
  end
end

