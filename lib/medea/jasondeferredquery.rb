module Medea
  class JasonDeferredQuery
    require 'rest_client'

    attr_accessor :time_limit, :result_format

    def initialize a_class, format=:json
      @class = a_class
      @filters = {:FILTER => {:HTTP_X_CLASS => a_class.name.to_s}}
      @result_format = format
      @time_limit = 0
      @_state = :prefetch
      @contents = []
    end

    #Here we're going to put the "query" interface

    #here we will capture:
    #members_of(object) (where object is an instance of a class that this class can be a member of)
    #members_of_<classname>(key)
    #find_by_<property>(value)
    #Will return a JasonDeferredQuery for this class with the appropriate data filter set
    def method_missing(name, *args, &block)
      #if we are postfetch, we throw away all our cached results
      if @_state == :postfetch
        @_state = :prefetch
        @contents = []
      end

      if name =~ /^members_of$/
        #use the type and key of the first arg (being a JasonObject)
        #args[0] must be a JasonObject (or child)
        raise ArgumentError, "When looking for members, you must pass a JasonObject" unless args[0].is_a? JasonObject

        @filters[:DATA_FILTER] ||= {}
        @filters[:DATA_FILTER]["__member_of"] ||= []
        @filters[:DATA_FILTER]["__member_of"] << args[0].jason_key
      elsif name =~ /^find_by_(.*)$/
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
    #end query interface

    def add_data_filter property, value
      @filters[:DATA_FILTER] ||= {}
      @filters[:DATA_FILTER][property] = value
    end

    def to_url
      url = "#{JasonDB::db_auth_url}@#{@time_limit}.#{@result_format}?"
      filter_array = []
      @filters.each do |name, val|
        if not val
          filter_array << name.to_s
          next
        else
          #FILTER's value is a hash (to avoid dupes)
          #DATA_FILTER's value is a hash
          if val.is_a? Hash
            #for each k/v in the hash, we want to add an entry to filter_array
            val.each do |field ,value|
              if value.is_a? Array
                value.each do |i|
                  filter_array << "#{name.to_s}=#{field}:#{i}"
                end
              else
                filter_array << "#{name.to_s}=#{field.to_s}:#{value.to_s}"
              end
            end
          end
        end
      end

      url + filter_array.join("&")
    end

    #array access interface
    def [](index)
      execute_query unless @_state == :postfetch
      @contents[index]
    end

    def each(&block)
      execute_query unless @_state == :postfetch
      @contents.each &block
    end

    def count
      execute_query unless @_state == :postfetch
      @contents.count
    end
    #end array interface

    private
    def execute_query
      #hit the URL
      #fill @contents with :ghost versions of JasonObjects
      begin
        #puts "Executing #{@class.name} deferred query! (#{to_url})"
        result = JSON.parse(RestClient.get to_url)

        #results are in a hash, their keys are just numbers
        result.keys.each do |k|
          if k =~ /^[0-9]+$/
            #this is a result! get the key
            /\/([^\/]*)\/([^\/]*)$/.match result[k]["POST_TO"]
            #$1 is the class name, $2 is the key
            item = @class.new($2, :lazy)
            @contents << item
          end
        end
      rescue
        @contents = []
      ensure
        @_state = :postfetch
      end
    end
  end
end