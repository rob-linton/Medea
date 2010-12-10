#Medea/JasonObject - Written by Michael Jensen

module Medea
  require 'rest_client'
  require 'json'

  class JasonObject

    #include JasonDB

    #Here we're going to put the "query" interface

    #create a JasonDeferredQuery with no conditions, other than HTTP_X_CLASS=self.name
    #if mode is set to :eager, we create the JasonDeferredQuery, invoke it's execution and then return it
    def JasonObject.all(mode=:lazy)
      #TODO Implement after JasonDeferredQuery is
    end

    #returns the JasonObject by directly querying the URL
    #if mode is :lazy, we return a GHOST, if mode is :eager, we return a STALE JasonObject
    def JasonObject.get_by_key(key, mode=:eager)
      return self.new key
    end

    #here we will capture:
    #members_of_<class>(key)
    #members_of(object) (where object is an instance of a class that this class can be a member of)
    #find_by_<property>(value)
    #Will return a JasonDeferredQuery for this class with the appropriate data filter set
    def JasonObject.method_missing(name, *args, &block)
      if name =~ /^members_of$/
        #use the type and key of the first arg (being a JasonObject)
      elsif name =~ /^members_of_(.*)$/
        #use the class name from the name variable, and the key from the first arg (being a string)
      elsif name =~ /^find_by_(.*)$/
        #use the property name from the name variable, and the value from the first arg
      else
        #no method!
        super
      end
    end
    #end query interface

    #"flexihash" access interface
    def []=(key, value)
        @__jason_data[key] = value
    end

    def [](key)
        @__jason_data ||= {}
    end

    #The "Magic" component of candy (https://github.com/SFEley/candy), repurposed to make this a
    # "weak object" that can take any attribute.
    # Assigning any attribute will add it to the object's hash (and then be POSTed to JasonDB on the next save)
    def method_missing(name, *args, &block)
        self.load if @__jason_state == :ghost
        if name =~ /(.*)=$/  # We're assigning
            @__jason_state = :dirty if @__jason_state == :stale
            self[$1.to_sym] = args[0]
        elsif name =~ /(.*)\?$/  # We're asking
            (self[$1.to_sym] ? true : false)
        else
            self[name]
        end
    end
    #end "flexihash" access

    def initialize key = nil
      if key
        @__id = key
        load
      else
        @__jason_state = :new
        @__jason_data = {}
      end
    end

    def jason_key
        #TODO: Replace this string with a guid generator of some kind
        @__id ||= "p#{Time.now.nsec.to_s}"
    end

    def jason_state
      @__jason_state
    end

    def jason_etag
      @__jason_etag ||= ""
    end

    #object persistence methods

    #POSTs the current values of this object back to JasonDB
    #on successful post, sets state to STALE and updates eTag
    def save!
        #no changes? no save!
        return if @__jason_state == :stale or @__jason_state == :ghost
        payload = self.to_json
        post_headers = {
            :content_type => 'application/json',
            "X-CLASS" => self.class.name,
            "X-KEY" => self.jason_key
            #also want to add the eTag here!
            #may also want to add any other indexable fields that the user specifies?
            #may also want to add this object's guid?
        }
        post_headers["IF-MATCH"] = @__jason_etag if @__jason_state == :dirty

        #puts "Posted to JasonDB!"
        url = JasonDB::db_auth_url + self.class.name + "/" + self.jason_key
        puts "Saving to #{url}"
        response = RestClient.post url, payload, post_headers

        if response.code == 201
            #save successful!
            #store the new eTag for this object
            puts response.raw_headers
            #@__jason_etag = response.headers[:location] + ":" + response.headers[:content_md5]
        else
            raise "POST failed! Could not save object"
        end

        @__jason_state = :stale
    end

    def delete!
      url = "#{JasonDB::db_auth_url}#{self.class.name}/#{self.jason_key}"
      response = RestClient.delete url
      raise "DELETE failed!" unless response.code == 201
    end

    #end object persistence

    #converts the data hash (that is, @__jason_data) to JSON format
    def to_json
      JSON.generate(@__jason_data)
    end

    private

    #fetches the data from the JasonDB
    def load
      url = "#{JasonDB::db_auth_url}#{self.class.name}/#{self.jason_key}"
      puts "Retrieving #{self.class.name} at #{url}"
      response = RestClient.get url
      @__jason_data = JSON.parse response
      @__jason_etag = response.headers[:etag]
      @__jason_state = :stale
    end

    def lazy_load meta
      #TODO Implement lazy load
      
      @__jason_state = :ghost
    end

  end
end