module Medea
  require 'uri'
  require 'rest_client'
  class JasonListProperty < JasonDeferredQuery

    attr_accessor :list_name, :parent, :list_type

    def initialize parent, list_name, list_class, list_type
      @type = list_class
      @list_name = list_name
      @list_type = list_type
      @parent = parent
      @result_format = :json
      @time_limit = 0
      @state = :prefetch
      @contents = []
    end

    def method_missing name, *args, &block
      #is this a list property on the base class?
      if @type.class_variable_get(:@@lists).has_key? name
        #if so, we'll just return a new ListProperty with my query as the parent
        new_list_class, new_list_type = @type.class_variable_get(:@@lists)[name]
        base_query = self.clone
        base_query.result_format = :keylist
        JasonListProperty.new base_query, name.to_sym, new_list_class, new_list_type
      else
        #no method, let JasonDeferredQuery handle it
        super
      end
    end

    def add! member, save=true
      raise RuntimeError, "You can only add an item if you are accessing this list from an object." unless @parent.is_a? JasonObject
      raise ArgumentError, "You can only add #{@type.name} items to this collection!" unless member.is_a? @type
      
      if @list_type == :value
        member.jason_parent = @parent
        member.jason_parent_list = @list_name
      elsif @list_type == :reference

        #post to JasonDB::db_auth_url/a_class.name/
        url = "#{JasonDB::db_auth_url}#{@type.name}/#{@parent.jason_key}/#{@list_name}/#{member.jason_key}"
        post_headers = {
              :content_type => 'application/json',
              "X-CLASS" => @list_name.to_s,
              "X-KEY" => member.jason_key,
              "X-PARENT" => @parent.jason_key
        }
        content = {
            "_id" => member.jason_key,
            "_parent" => @parent.jason_key
        }
        puts url
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
      else
        #parent is a JasonObject, but this list is something other than :value or :reference??
        raise "Invalid list type or trying to add an item to a subquery list!"
      end

      if member.jason_state == :new
        #we want to save it? probably...
        member.save! if save
      end

      @state = :prefetch
    end

    def to_url
      url = "#{JasonDB::db_auth_url}@#{@time_limit}.#{@result_format}?"
      params = ["VERSION0"]

      params << "FILTER=HTTP_X_CLASS:#{@list_name.to_s}"

      if @parent.is_a? JasonObject
        params << "FILTER=HTTP_X_PARENT:#{@parent.jason_key}"
      else # @parent.is_a? JasonListProperty ##(or DeferredQuery?)
        subquery = URI.escape("<%@LANGUAGE=\"URL\" #{@parent.to_url}%>", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        params << "FILTER={HTTP_X_PARENT:#{subquery}}"
      end

      url << params.join("&")
    end
  end
end