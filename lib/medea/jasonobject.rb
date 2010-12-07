#Medea/JasonObject - Written by Michael Jensen

module Medea
    class JasonObject
    
        include JasonDB
    
        def []=(key, value)
            @__jason_data[key] = value
        end
    
        def [](key)
            @__jason_data ||= {}
        end
        
        def id
            #TODO: Replace this string with a guid generator of some kind
            @__id ||= "123456789-123456789"
        end
        
        #The "Magic" component of candy (https://github.com/SFEley/candy), repurposed to make this a
        # "weak object" that can take any attribute.
        # Assigning any attribute will add it to the object's hash (and then be POSTed to JasonDB on the next save)
        def method_missing(name, *args, &block)
            if name =~ /(.*)=$/  # We're assigning
                self[$1.to_sym] = args[0]
            elsif name =~ /(.*)\?$/  # We're asking
                (self[$1.to_sym] ? true : false)
            else
                self[name]
            end
        end
        
        
        def save!
            payload = self.to_json
            post_headers = {
                :content_type => 'application/json',
                "X-CLASS" => self.class
                #also want to add the eTag here!
                #may also want to add any other indexable fields that the user specifies?
                #may also want to add this object's guid?
            }
            
            response = RestClient.post db_auth_url, payload, post_headers
            
            if response.code == 201
                #save successful!
                #store the new eTag for this object
            else
                raise "POST failed! Could not save object"
            end
        end
        
        private
        
        require 'json'
        require 'rest_client'
        
        #fetches the data from the JasonDB
        def load
            
            
        end
        
        #converts the data hash (that is, @__jason_data) to JSON format
        def to_json
        
        end
    end
end