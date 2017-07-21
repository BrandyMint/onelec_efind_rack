require 'logger'
require 'pg'
require 'active_support/core_ext/string'

class EfindApp
  def initialize
    @error_logger =  Logger.new('log/app_errors.log')
    @conn = PG.connect( dbname: 'onelec_production_2017' )
  end

  def call(env)
    req = Rack::Request.new(env)
    query = req.params["search"].to_s.gsub(/[^[:alnum:]\s]/, '').squish.gsub(' ', '&')
    data = query.present? ? fetch_results(query) : []
    response = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><data>"
    response << data.map {|q| q["efind_xml"] }.join('')
    response << '</data>'
    [200, {"Content-Type" => "application/xml"}, [response]]
  end

  private

  def fetch_results(query)
    begin
      sql = "SELECT efind_xml FROM \"product_efind_entities\" WHERE #{ts_query(query)} ORDER BY #{ts_rank(query)} desc LIMIT 20"

      @conn.exec(sql)
    rescue => e
      @error_logger << "query: #{query}\n message:#{e.message}\n#{e.backtrace.join("\n")}\n"

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

