module JasonDB
  def JasonDB::class_exists? class_name
    const = Module.const_get(class_name)
    return const.is_a? Class
  rescue NameError
    return false
  end

  #jason_url here doesn't include the http[s]:// part, but does include the domain and a trailing '/'
  #( so it's "rest.jasondb.com/<domain>/" )
  def JasonDB::db_auth_url mode=:secure
    #check to see if this is a Rails environment
    if class_exists? "Rails"
      config = Rails.configuration.database_configuration[Rails.env]
    else
      #if not, use some defaults for testing medea.
      config = {"user" => "michael",
                "topic" => "medea-test",
                "password" => "password"}
    end

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
