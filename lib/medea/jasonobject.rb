#Medea/JasonObject - Written by Michael Jensen

module Medea
  require 'rest_client'
  require 'json'
  require 'uuidtools'

  class JasonObject

    #include JasonDB

    #meta-programming interface for lists
    include ClassLevelInheritableAttributes
    inheritable_attributes :owned
    @owned = false

    include JasonObjectListProperties

    #end meta

    #Here we're going to put the "query" interface

    #create a JasonDeferredQuery with no conditions, other than HTTP_X_CLASS=self.name
    #if mode is set to :eager, we create the JasonDeferredQuery, invoke it's execution and then return it
    def JasonObject.all(mode=:lazy)
      JasonDeferredQuery.new self
    end

    #returns the JasonObject by directly querying the URL
    #if mode is :lazy, we return a GHOST, if mode is :eager, we return a STALE JasonObject
    def JasonObject.get_by_key(key, mode=:eager)
      return self.new key, mode
    end

    #here we will capture:
    #members_of(object) (where object is an instance of a class that this class can be a member of)
    #find_by_<property>(value)
    #Will return a JasonDeferredQuery for this class with the appropriate data filter set
    def JasonObject.method_missing(name, *args, &block)
      q = JasonDeferredQuery.new self
      if name.to_s =~ /^members_of$/
        #use the type and key of the first arg (being a JasonObject)
        return q.members_of args[0]
      elsif name.to_s =~ /^find_by_(.*)$/
        #use the property name from the name variable, and the value from the first arg
        q.add_data_filter $1, args[0]

        return q
      else
        #no method!
        super
      end
    end
    #end query interface

    #"flexihash" access interface
    def []=(key, value)
      @__jason_data ||= {}
      @__jason_data[key] = value
    end

    def [](key)
      @__jason_data[key]
    end

    #The "Magic" component of candy (https://github.com/SFEley/candy), repurposed to make this a
    # "weak object" that can take any attribute.
    # Assigning any attribute will add it to the object's hash (and then be POSTed to JasonDB on the next save)
    def method_missing(name, *args, &block)
        load if @__jason_state == :ghost
        field = name.to_s
        if field =~ /(.*)=$/  # We're assigning
            @__jason_state = :dirty if @__jason_state == :stale
            self[$1] = args[0]
        elsif field =~ /(.*)\?$/  # We're asking
            (self[$1] ? true : false)
        else
            self[field]
        end
    end
    #end "flexihash" access

    def initialize key = nil, mode = :eager
      if key
        @__id = key
        if mode == :eager
          load
        else
          @__jason_state = :ghost
        end
      else
        @__jason_state = :new
        @__jason_data = {}
      end
    end

    def jason_key
        #Generate a random UUID for this object.
	#since jason urls must start with a letter, we'll use the first letter of the class name
        @__id ||= "#{self.class.name[0].chr.downcase}#{UUIDTools::UUID::random_create.to_s}"
    end

    def to_s
      jason_key
    end

    def jason_state
      @__jason_state
    end

    def jason_etag
      @__jason_etag ||= ""
    end

    def jason_parent
      @__jason_parent ||= nil
    end

    def jason_parent_list
      @__jason_parent_list ||= nil
    end

    def jason_parent_list= value
      @__jason_parent_list = value
    end

    def jason_parent= parent
      @__jason_parent = parent
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

            "X-KEY" => self.jason_key,
            "X-CLASS" => self.class.name
            #also want to add the eTag here!
            #may also want to add any other indexable fields that the user specifies?
        }
        post_headers["IF-MATCH"] = @__jason_etag if @__jason_state == :dirty

        if self.class.owned
          #the parent object needs to be defined!
          raise "#{self.class.name} cannot be saved without setting a parent and list!" unless self.jason_parent && self.jason_parent_list
          post_headers["X-PARENT"] = self.jason_parent.jason_key
          url = "#{JasonDB::db_auth_url}#{self.jason_parent.class.name}/#{self.jason_parent.jason_key}/#{self.jason_parent_list}/#{self.jason_key}"
          post_headers["X-LIST"] = self.jason_parent_list
        else
          url = JasonDB::db_auth_url + self.class.name + "/" + self.jason_key
        end


        #puts "Posted to JasonDB!"

        #puts "Saving to #{url}"
        response = RestClient.post url, payload, post_headers

        if response.code == 201
            #save successful!
            #store the new eTag for this object
            #puts response.raw_headers
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
      #because this object might be owned by another, we need to search by key.
      #not passing a format to the query is a shortcut to getting just the object.
      url = "#{JasonDB::db_auth_url}@0.content?"
      params = [
          "VERSION0",
          "FILTER=HTTP_X_CLASS:#{self.class.name}",
          "FILTER=HTTP_X_KEY:#{self.jason_key}"
      ]

      url << params.join("&")

      #puts "   = Retrieving #{self.class.name} at #{url}"
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
