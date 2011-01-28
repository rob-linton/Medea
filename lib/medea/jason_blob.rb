module Medea
  class JasonBlob < JasonBase
    def initialize initialiser=nil, mode=:eager
      if initialiser
        @__id = initialiser
        if mode == :eager
          load_from_jasondb
        else
          @__jason_state = :ghost
        end
      else
        @__jason_state = :new
        @__jason_data = nil
      end
    end

    def load_from_jasondb
      #because this object might be owned by another, we need to search by key.
      #not passing a format to the query is a shortcut to getting just the object.
      url = build_url()

      response = RestClient.get url

      #don't JSON parse blob data!
      @__jason_data = response
      @__jason_etag = response.headers[:etag]
      @__jason_state = :stale
    end

    def contents
      @__jason_data
    end

    def contents= data
      @__jason_data = data
      @__jason_state = :dirty
    end
  end
end
