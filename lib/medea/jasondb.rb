module JasonDB
    #jason_url here doesn't include the http[s]:// part, but does include the domain and a trailing '/'
    #( so it's "rest.jasondb.com/<domain>/" )
    attr_accessor :jason_url, :user, :password



    def JasonDB::db_auth_url
      user = "michael"
      jason_url = "rest.jasondb.com/michael/"
      password = "password"
      "https://#{user}:#{password}@#{jason_url}"
    end

end