module JasonDB
    #jason_url here doesn't include the http[s]:// part, but does include the domain and a trailing '/'
    #( so it's "rest.jasondb.com/<domain>/" )
    attr_accessor :jason_url, :user, :password
    
    def db_auth_url
        "https://#{self.user}:#{self.password}@#{self.jason_url}"
    end

end