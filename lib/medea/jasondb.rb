module JasonDB
  #jason_url here doesn't include the http[s]:// part, but does include the domain and a trailing '/'
  #( so it's "rest.jasondb.com/<domain>/" )
  def JasonDB::db_auth_url mode=:secure
    config = Rails.configuration.database_configuration[Rails.env]
    
    user = config["user"]
    topic = config["topic"]
    password = config["password"]
    if config["jason_host"]
      host = config["jason_host"]
    else
      host = "rest.jasondb.com"
    end
    protocol = "http"
    protocol << "s" if mode == :secure
    "#{protocol}://#{user}:#{password}@#{host}/#{topic}/"
  end

end
