require 'logger'
require 'pg'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_record'
# require 'pry'

class EfindApp
  def initialize
    @logger =  Logger.new('log/application.log')
    @logger.info "Start app"

    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml')))
  end

  def call(env)
    req = Rack::Request.new(env)

    version = req.path.split('/').include?('v2') ? 'v2' : 'v1'

    query = req.params["search"].to_s.gsub(/[^[:alnum:]\s]/, '').squish.gsub(' ', '&')

    data = (query.present? && query.length > 3) ? fetch_results(query, version) : []

    if req.path.include?('chipfind')
      data = data.map do |str|
        hash = Hash.from_xml(str)['line']

        hash["cur"] = 'RUB' if hash["cur"].present?

        if hash["img"].present?
          hash["img"].gsub!('https', 'http')
          hash["img"].gsub!('efind', 'chipfind')
        end

        hash.to_xml(skip_instruct: true, skip_types: true, indent: 0, root: :line).squish
      end

      log_search(query, data.count, 'chipfind')
    else
      log_search(query, data.count, 'efind')
    end

    ActiveRecord::Base.clear_active_connections!

    response = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    response << (version == 'v2' ? '<data version="2.0">' : '<data>')
    response << data.join('')
    response << '</data>'

    [200, {"Content-Type" => "application/xml"}, [response]]
  end

  private

  # chipfind и einfo на старой спецификации
  def fetch_results(query, version)
    table = version == 'v2' ? 'product_efind_v2_entities' : 'product_efind_entities'

    sql = "SELECT efind_xml FROM \"#{table}\" WHERE #{ts_query(query, table)} ORDER BY #{ts_rank(query)} desc LIMIT 20"

    ActiveRecord::Base.connection.select_values sql
  rescue => e
    @logger.error "Time:#{Time.now}\nquery: #{query}\nmessage:#{e.message}\n#{e.backtrace.join("\n")}\n"

    []
  end

  def ts_query(query, table)
    "(to_tsvector('simple', #{table}.name_ts) @@ to_tsquery('simple', '#{query}:*'))"
  end

  def ts_rank(query)
    "ts_rank_cd(to_tsvector('simple', name_ts), to_tsquery('simple', '#{query}'))"
  end

  def log_search(query, products_count, type)
    return if query.blank?

    @logger.info "query=#{query};products_count=#{products_count};type=#{type}"
    # ActiveRecord::Base.connection.execute("INSERT INTO search_logs (query, products_count, search_type, created_at, updated_at) VALUES ('#{query}', #{products_count}, '#{type}', now(), now())")
  end
end

