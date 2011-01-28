module Medea
  class JasonBase
    #meta-programming interface for lists
    include ClassLevelInheritableAttributes
    inheritable_attributes :owned
    @owned = false

    
    #returns the JasonObject by directly querying the URL
    #if mode is :lazy, we return a GHOST, if mode is :eager, we return a STALE JasonObject
    def self.get_by_key(key, mode=:eager)
      return self.new key, mode
    end

    #the resolve method takes a key and returns the JasonObject that has that key
    #This is useful when you have the key, but not the class
    def self.resolve(key, mode=:lazy)
      q = JasonDeferredQuery.new :filters => {:VERSION0 => nil, :FILTER => {:HTTP_X_KEY => key, :HTTP_X_ACTION => :POST}}
      q.filters[:FILTER] ||= {}
      q.filters[:FILTER][:HTTP_X_KEY] = key
      resp = JSON.parse(RestClient.get(q.to_url))
      if resp.has_key? "1"
        #this is the object, figure out its class
        resp["1"]["POST_TO"] =~ /([^\/]+)\/#{key}/
        begin
          result = Kernel.const_get($1).get_by_key key, :lazy
          if result["1"].has_key? "CONTENT"
            result.instance_variable_set(:@__jason_data, result["1"]["CONTENT"])
            result.instance_variable_set(:@__jason_state, :stale)
          end
          if mode == :eager
            result.send(:load)
          end
        rescue
          nil
        end
      end
    end

    def ==(other)
      return false if not other.is_a? JasonBase
      jason_key == other.jason_key
    end

    def jason_key
        #Generate a random UUID for this object.
	      #since jason urls must start with a letter, we'll use the first letter of the class name
        @__id ||= "#{self.class.name[0].chr.downcase}#{UUIDTools::UUID::random_create.to_s}"
    end

    def jason_state
      @__jason_state
    end

    def jason_etag
      @__jason_etag ||= ""
    end

    def jason_parent
      @__jason_parent ||= nil
      if @__jason_parent == nil && @__jason_parent_key
        #key is set but parent not? load the parent
        @__jason_parent = JasonObject.resolve @__jason_parent_key
      end
      @__jason_parent
    end

    def jason_parent= parent
      @__jason_parent = parent
      @__jason_parent_key = parent.jason_key
    end

    def jason_parent_key
      @__jason_parent_key ||= nil
    end

    def jason_parent_key= value
      @__jason_parent_key = value
      #reset the parent here?
      @__jason_parent = nil
    end

    def jason_parent_list
      @__jason_parent_list ||= nil
    end

    def jason_parent_list= value
      @__jason_parent_list = value
    end

    #POSTs the current values of this object back to JasonDB
    #on successful post, sets state to STALE and updates eTag
    def save
      return false if @__jason_state == :stale or @__jason_state == :ghost
      begin
        save!
        return true
      rescue
        return false
      end
    end
    def save!
        #no changes? no save!
        return if @__jason_state == :stale or @__jason_state == :ghost

        persist_changes :post
    end

    def delete! cascade=false
      #TODO: Put this into some kind of async method or have JasonDB able to set flags on many records at once
      #This will be REALLY REALLY slowww!
      if cascade && (self.class.class_variable_defined? :@@lists)
        @@lists.keys.each do |list_name|
          #for each list that I have
          list = send(list_name)
          list.each do |item|
            #remove each item from the list, deleting it if possible
            list.remove! item, true
          end
        end
      end
      persist_changes :delete
    end

    def build_url
      url    = "#{JasonDB::db_auth_url}@0.content?"
      params = [
          "VERSION0",
          "FILTER=HTTP_X_KEY:#{self.jason_key}",
          "FILTER=HTTP_X_CLASS:#{self.class.name}"
      ]

      url << params.join("&")
      url
    end


    #fetches the data from the JasonDB
    def load_from_jasondb
      #because this object might be owned by another, we need to search by key.
      #not passing a format to the query is a shortcut to getting just the object.
      url = build_url()
      
      response = RestClient.get url
      @__jason_data = JSON.parse response
      @__jason_etag = response.headers[:etag]
      @__jason_state = :stale
    end

    def persist_changes method = :post
      payload = self.serialise

      post_headers = {
          :content_type => 'application/json',
          "X-KEY"       => self.jason_key,
          "X-CLASS"     => self.class.name
          #also want to add the eTag here!
          #may also want to add any other indexable fields that the user specifies?
      }
      post_headers["IF-MATCH"] = @__jason_etag if @__jason_state == :dirty

      if self.class.owned
        #the parent object needs to be defined!
        raise "#{self.class.name} cannot be saved without setting a parent and list!" unless self.jason_parent && self.jason_parent_list
      end

      post_headers["X-PARENT"] = self.jason_parent.jason_key if self.jason_parent
      post_headers["X-LIST"] = self.jason_parent_list if self.jason_parent_list

      url = JasonDB::db_auth_url + self.class.name + "/" + self.jason_key

      #puts "Saving to #{url}"
      if method == :post
        response = RestClient.post(url, payload, post_headers)
      elsif method == :delete
        response = RestClient.delete(url, post_headers)
      else
        raise "Unknown method '#{method.to_s}'"
      end

      if response.code == 201
        #save successful!
        #store the new eTag for this object
        #puts response.raw_headers
        #@__jason_etag = response.headers[:location] + ":" + response.headers[:content_md5]
      else
        raise "#{method.to_s.upcase} failed! Could not persist changes"
      end

      @__jason_state = :stale
    end
  end
end