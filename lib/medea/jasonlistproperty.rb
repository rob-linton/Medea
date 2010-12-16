module Medea
  require 'cgi'
  require 'rest_client'
  class JasonListProperty < JasonDeferredQuery

    attr_accessor :list_name, :init_query

    def initialize a_class, list_name, init_query, source=:object
      #inspect the class a_class and see if it has any list properties
      #these will have been defined with has_many and owns_many
      @type = a_class
      @list_name = list_name
      @init_query = init_query
      @source = source
      @result_format = :json
      @time_limit = 0
      @state = :prefetch
      @contents = []
    end

    def method_missing name, *args, &block
      #is this a list property on the base class?
      if @type.class_variable_get(:@@lists).has_key? name
        #if so, we'll just return a new ListProperty with my query as the init_query
        JasonListProperty.new @type.class_variable_get(:@@lists)[name], name.to_s, to_url, :list
      else
        #no method, let JasonDeferredQuery handle it
        super
      end
    end

    def add! member
      raise ArgumentError, "You can only add #{@type.name} items to this collection!" unless member.is_a? @type
      raise RuntimeError, "You can only add an item if you are accessing this list from an object." if @source == :list
      
      if member.jason_state == :new
        #we want to save it first? probably...
        member.save!
      end
      #post to JasonDB::db_auth_url/a_class.name/
      url = "#{JasonDB::db_auth_url}#{@type.name}/#{@init_query}/#{@list_name}/#{member.jason_key}"
      post_headers = {
            :content_type => 'application/json',
            "HTTP_X_CLASS" => @list_name,
            "HTTP_X_KEY" => member.jason_key,
            "HTTP_X_PARENT" => @init_query
      }
      content = {
          "_id" => member.jason_key,
          "_parent" => @init_query
      }
      puts post_headers
      response = RestClient.post url, content.to_json, post_headers

      if response.code == 201
          #save successful!
          #store the new eTag for this object
          #puts response.raw_headers
          #@__jason_etag = response.headers[:location] + ":" + response.headers[:content_md5]
      else
          raise "POST failed! Could not save membership"
      end

    end

    def to_url
      url = "#{JasonDB::db_auth_url}@#{time_limit}.#{result_format}?"
      params = ["VERSION0",
                "FAST",
                "FILTER=HTTP_X_PARENT:#{@init_query}"]
      if self.type.class_variable_defined? :@@owner
         params << "FILTER=HTTP_X_CLASS:#{@type.name}"
      else
        params << "FILTER=HTTP_X_CLASS:#{@list_name}"
      end

      url << params.join("&")
    end
  end
end