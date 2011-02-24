module Medea
  require 'uri'
  require 'rest_client'
  class JasonListProperty < JasonDeferredQuery

    attr_accessor :list_name, :parent, :list_type

    def initialize parent, list_name, list_class, list_type
      super :class => list_class,
            :format => :search,
            :filters => {
                :VERSION0 => nil,
                :FILTER => {:HTTP_X_LIST => list_name,
                            :HTTP_X_ACTION => :POST}}

      self.filters[:FILTER][:HTTP_X_CLASS] = list_class.name if list_type == :value
      @list_name = list_name
      @parent = parent
      @state = :prefetch
      @contents = []
      @list_type = list_type
    end

    def method_missing name, *args, &block
      #is this a list property on the base class?
      lists = @type.class_variable_defined?(:@@opts) ? (@type.class_variable_get :@@opts)[:lists] : nil
      if lists && lists.has_key?(name)
        #if so, we'll just return a new ListProperty with my query as the parent
        new_list_class, new_list_type = lists[name]
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

        url = "#{JasonDB::db_auth_url}#{@parent.class.name}/#{@parent.jason_key}/#{@list_name}/#{member.jason_key}"
        post_headers = {
              :content_type => 'application/json',
              "X-KEY" => member.jason_key,
              "X-PARENT" => @parent.jason_key,
              "X-LIST" => @list_name.to_s
        }
        content = {
            "_id" => member.jason_key,
            "_parent" => @parent.jason_key
        }
        #puts "   = " + url
        #puts "   = #{post_headers}"
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

    def remove! member, cascade=false
      raise RuntimeError, "You can only remove an item if you are accessing this list from an object (ie, not another list)." unless @parent.is_a? JasonObject
      raise ArgumentError, "You can only remove #{@type.name} items from this collection!" unless member.is_a? @type
      raise ArgumentError, "This item (#{member.jason_key}) doesn't exist in the list you're trying to remove it from!" unless self.include? member
      
      if @list_type == :value
        member.jason_parent = nil
        member.jason_parent_list = nil
        member.delete! if cascade
      elsif @list_type == :reference

        #send DELETE to JasonDB::db_auth_url/a_class.name/
        url = "#{JasonDB::db_auth_url}#{@parent.class.name}/#{@parent.jason_key}/#{@list_name}/#{member.jason_key}"

        response = RestClient.delete url

        if response.code == 201
            #delete successful!
        else
            raise "DELETE failed! Could not remove membership"
        end
      else
        #parent is a JasonObject, but this list is something other than :value or :reference??
        raise "Invalid list type or trying to remove an item from a subquery list!"
      end

      @state = :prefetch
    end

    def execute_query
      #call super, but don't use the content to populate if this is a reference list
      content = @list_type == :reference ? false : true
      super content
    end


    def to_url
      url = "#{JasonDB::db_auth_url}@#{@time_limit}.#{@result_format}?"
      params = ["VERSION0"]
      params << "FILTER=HTTP_X_LIST:#{@list_name.to_s}"

      if @parent.is_a? JasonObject
        params << "FILTER=HTTP_X_PARENT:#{@parent.jason_key}"
      else # @parent.is_a? JasonListProperty ##(or DeferredQuery?)
        #we can get the insecure url here, because it will be resolved and executed at JasonDB - on a secure subnet.

        #puts "   = Fetching subquery stupidly. (#{@parent.to_url})"
        @parent.result_format = :keylist
        subquery = (RestClient.get @parent.to_url).strip
        #puts "   =   Result: #{subquery}"
        params << "FILTER={HTTP_X_PARENT:#{subquery}}"
      end

      url << URI.escape(params.join("&"), Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
  end
end