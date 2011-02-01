#Medea/JasonObject - Written by Michael Jensen

module Medea
  require 'rest_client'
  require 'json'
  require 'uuidtools'

  class JasonObject < JasonBase

    include Medea::ActiveModelMethods
    if defined? ActiveModel
      extend ActiveModel::Naming
    end

    include JasonObjectMetaProperties
    attr_accessor :attachments
    #end meta

    #Here we're going to put the "query" interface

    #create a JasonDeferredQuery with no conditions, other than HTTP_X_CLASS=self.name
    #if mode is set to :eager, we create the JasonDeferredQuery, invoke it's execution and then return it
    def JasonObject.all(mode=:lazy)
      JasonDeferredQuery.new :class => self, :filters => {:VERSION0 => nil, :FILTER => {:HTTP_X_CLASS => self, :HTTP_X_ACTION => :POST}}
    end

    #here we will capture:
    #members_of(object) (where object is an instance of a class that this class can be a member of)
    #find_by_<property>(value)
    #Will return a JasonDeferredQuery for this class with the appropriate data filter set
    def JasonObject.method_missing(name, *args, &block)

      q = all
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
      if @attachments.keys.include? key.to_sym
        @attachments[key.to_sym] = Medea::JasonBlob.new({:parent => self, :name => key, :content => value})
        return
      end
      @__jason_data ||= {}
      @__jason_state = :dirty if jason_state == :stale

      @__jason_data[key] = value
    end

    def [](key)
      if @attachments.keys.include? key.to_sym
        if not @attachments[key.to_sym]
          #retrieve the JasonBlob for this key
          @attachments[key.to_sym] = Medea::JasonBlob.new({:parent => self, :name => key})
        end

        return @attachments[key.to_sym]
      end
      @__jason_data[key]
    end

    #The "Magic" component of candy (https://github.com/SFEley/candy), repurposed to make this a
    # "weak object" that can take any attribute.
    # Assigning any attribute will add it to the object's hash (and then be POSTed to JasonDB on the next save)
    def method_missing(name, *args, &block)
        load_from_jasondb if @__jason_state == :ghost
        field = name.to_s
        if field =~ /(.*)=$/  # We're assigning
            self[$1] = args[0]
        elsif field =~ /(.*)\?$/  # We're asking
            (self[$1] ? true : false)
        else
            self[field]
        end
    end
    #end "flexihash" access

    def sanitize hash
      #remove the keys in hash that aren't allowed
      forbidden_keys = ["jason_key",
                        "jason_state",
                        "jason_parent",
                        "jason_parent_key",
                        "jason_parent_list"]
      hash.delete_if { |k,v| forbidden_keys.include? k }
      result = {}
      hash.each { |k, v| result[k.to_s] = v }
      result
    end

    def initialize initialiser = nil, mode = :eager
      @attachments = {}
      if self.class.class_variable_defined? :@@attachments
        (self.class.class_variable_get :@@attachments).each do |k|
          @attachments[k] = nil
        end
      end

      if initialiser
        if initialiser.is_a? Hash
          @__jason_state = :new
          @__jason_data = sanitize initialiser
        else
          @__id = initialiser
          if mode == :eager
            load_from_jasondb
          else
            @__jason_state = :ghost
          end
        end
      else
        @__jason_state = :new
        @__jason_data = {}
      end
    end

    def to_s
      jason_key
    end

    #converts the data hash (that is, @__jason_data) to JSON format
    def serialise
      JSON.generate(@__jason_data)
    end

    #object persistence methods

    def update_attributes attributes
      @__jason_data = sanitize attributes
      @__jason_state = :dirty unless @__jason_state == :new
      save
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
        @attachments.each do |k, v|
          if v
            v.save!
          end
        end

        #no changes? no save!
        return if @__jason_state == :stale or @__jason_state == :ghost

        persist_changes :post
    end

    def to_url
      "#{JasonDB::db_auth_url}#{self.class.name}/#{self.jason_key}"
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

      url = to_url()

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

    #end object persistence
  end
end
