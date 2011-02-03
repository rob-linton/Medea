module Medea
  class   JasonDeferredQuery
    require 'rest_client'
    require 'uri'

    attr_accessor :time_limit, :result_format, :type, :time_limit, :state, :contents, :filters

    def initialize opts={}
      self.type = opts[:class] if opts[:class]
      self.filters = opts[:filters] if opts[:filters]
      self.result_format = opts[:format] ? opts[:format] : :search
      self.time_limit = opts[:time_limit] ? opts[:time_limit] : 0
      self.state = :prefetch
      self.contents = []
    end

    #Here we're going to put the "query" interface

    #here we will capture:
    #members_of(object) (where object is an instance of a class that this class can be a member of)
    #members_of_<classname>(key)
    #find_by_<property>(value)
    #Will return a JasonDeferredQuery for this class with the appropriate data filter set
    def method_missing(name, *args, &block)
      #if we are postfetch, we throw away all our cached results
      if self.state == :postfetch
        self.state = :prefetch
        self.contents = []
      end

      field = name.to_s	

      if field =~ /^members_of$/
        #use the type and key of the first arg (being a JasonObject)
        #args[0] must be a JasonObject (or child)
        raise ArgumentError, "When looking for members, you must pass a JasonObject" unless args[0].is_a? JasonObject

        self.filters[:DATA_FILTER] ||= {}
        self.filters[:DATA_FILTER]["__member_of"] ||= []
        self.filters[:DATA_FILTER]["__member_of"] << args[0].jason_key
      elsif field =~ /^find_by_(.*)$/
        #use the property name from the name variable, and the value from the first arg
        add_data_filter $1, args[0].to_s
      else
        #no method!
        super
        return
      end
      #return self, so that we can chain up query refinements
      self
    end

    def limit n
      self.filters[:TOP] = n
    end

    def limit= n
      limit n
    end

    #synonym for limit
    def top n
      limit n
    end
    #end query interface

    def add_data_filter property, value
      self.filters[:DATA_FILTER] ||= {}
      self.filters[:DATA_FILTER][property] = value
    end

    def to_url
      url = "#{JasonDB::db_auth_url}@#{self.time_limit}.#{self.result_format}?"
      filter_array = []
      unsafe = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
      self.filters.each do |name, val|
        if not val
          filter_array << URI.escape(name.to_s, unsafe)
          next
        else
          #FILTER's value is a hash (to avoid dupes)
          #DATA_FILTER's value is a hash
          if val.is_a? Hash
            #for each k/v in the hash, we want to add an entry to filter_array
            val.each do |field ,value|
              if value.is_a? Array
                value.each do |i|
                  filter_array << URI.escape("#{name.to_s}=#{field}:#{i}", unsafe)
                end
              else
                filter_array << URI.escape("#{name.to_s}=#{field.to_s}:#{value.to_s}", unsafe)
              end
            end
          else
            filter_array << URI.escape("#{name.to_s}=#{val.to_s}", unsafe)
          end
        end
      end

      url + filter_array.join("&")
    end

    #array access interface
    def [](index)
      execute_query unless self.state == :postfetch
      self.contents[index]
    end

    def each(&block)
      execute_query unless self.state == :postfetch
      self.contents.each &block
    end

    def count
      execute_query unless self.state == :postfetch
      self.contents.count
    end

    def include?(item)
      execute_query unless self.state == :postfetch
      self.contents.each do |i|
        return true if i.jason_key == item.jason_key
      end
      false
    end
    #end array interface

    def execute_query content=true
      #hit the URL
      #fill self.contents with :ghost versions of JasonObjects
      
      begin
        response = RestClient.get to_url
        result = JSON.parse(response)
        self.contents = []
        #results are in a hash, their keys are just numbers
        result.keys.each do |k|
          if k =~ /^[0-9]+$/
            #this is a result! get the key
            item = type.new(result[k]["HTTP_X_KEY"], :lazy)
            if content && result[k].has_key?("CONTENT") && result[k]["CONTENT"] != ""
              item.instance_variable_set(:@__jason_data, result[k]["CONTENT"])
              item.instance_variable_set(:@__jason_state, :stale)
            end
            if result[k].has_key?("HTTP_X_PARENT") && result[k]["HTTP_X_PARENT"] != ""
              item.jason_parent_key = result[k]["HTTP_X_PARENT"]
            end
            self.contents << item
          end
        end

        self.state = :postfetch
      rescue JSON::ParserError
        #we assume that a parser error means that there are no results, or a problem with the template
        #(currently a problem with the template is causing a parser error when there's no results)
        self.contents = []
        self.state = :postfetch
      end
      result
    end
  end
end
