module Medea
  class JasonDeferredQuery
    def initialize class_name, format=:json
      @filters = {:FILTER => {:HTTP_X_CLASS => class_name}}
      @format = format
      @time_limit = 0
    end

    #Here we're going to put the "query" interface

    #here we will capture:
    #members_of(object) (where object is an instance of a class that this class can be a member of)
    #members_of_<classname>(key)
    #find_by_<property>(value)
    #Will return a JasonDeferredQuery for this class with the appropriate data filter set
    def method_missing(name, *args, &block)
      @filters[:DATA_FILTER] = {} unless @filters[:DATA_FILTER]
      if name =~ /^members_of$/
        #use the type and key of the first arg (being a JasonObject)
        #args[0] must be a JasonObject (or child)
        raise ArgumentError, "When looking for members, you must pass a JasonObject" unless args[0].is_a? JasonObject
        @filters[:DATA_FILTER]["__member_of"] = [] unless @filters[:DATA_FILTER]["__member_of"]
        @filters[:DATA_FILTER]["__member_of"] << args[0].jason_key
      elsif name =~ /^find_by_(.*)$/
        #use the property name from the name variable, and the value from the first arg
        @filters[:DATA_FILTER][$1] = args[0].to_s
      else
        #no method!
        super
      end
    end
    #end query interface

    def to_url
      url = "#{JasonDB::db_auth_url}@#{@time_limit}.#{@format}?"
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
  end
end