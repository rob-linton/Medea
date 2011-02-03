module Medea
  class JasonBase
    #meta-programming interface for lists
    include ClassLevelInheritableAttributes
    inheritable_attributes :owned
    @owned = false

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

    def jason_timestamp
      @__jason_timestamp
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
      url = to_url
      
      response = RestClient.get url
      @__jason_data = JSON.parse response
      @__jason_etag = response.headers[:etag]
      @__jason_timestamp = response.headers[:timestamp]
      @__jason_state = :stale
    end


  end
end