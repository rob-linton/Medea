module Medea
  class JasonBlob < JasonBase
    attr_accessor :parent, :attachment_name

    def initialize initialiser=nil, mode=:eager
      if initialiser
        if initialiser.is_a? Hash
          @parent = initialiser[:parent]
          @attachment_name = initialiser[:name]
          @__jason_state = :ghost
          if initialiser[:content]
            self.contents = initialiser[:content]
            @__jason_state = :new
          end
          return
        end
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

    def to_url
      "#{@parent.to_url}/#{@attachment_name}"
    end

    def load_from_jasondb
      #because this object might be owned by another, we need to search by key.
      #not passing a format to the query is a shortcut to getting just the object.
      url = to_url
      response = nil
      begin
        response = RestClient.get url

        #don't JSON parse blob data!
        @__jason_data = response
        @__jason_etag = response.headers[:etag]
        @__jason_state = :stale
      rescue
        #an exception here means a bad url or a 404.
        #404 simply means no data yet for this attachment
        @__jason_state = :new
        @__jason_data = nil
        return
      end
    end

    def contents
      load_from_jasondb if @__jason_state == :ghost
      @__jason_data
    end

    def contents= data
      @__jason_data = data
      @__jason_state = :dirty
    end

    def set_content_type type=nil
      if type
        @content_type = type
      elsif contents.is_a? IO
        @content_type = image_type(contents)
      elsif contents.is_a? String
        @content_type = "text/plain"
      else
        @content_type = "application/octet-stream"
      end
    end

    def image_type(file)
        case IO.read(file, 10)
          when /^GIF8/; 'image/gif'
          when /^\x89PNG/; 'image/png'
          when /^\xff\xd8\xff\xe0\x00\x10JFIF/; 'image/jpeg'
          when /^\xff\xd8\xff\xe1(.*){2}Exif/; 'image/jpeg'
        else 'unknown'
        end
      end

    def save!
      return if @__jason_state == :stale or @__jason_state == :ghost
      set_content_type
      #write the contents of @__jason_data to parent url/attachment name
      post_headers = {
          :content_type => @content_type,
          :length       => contents.size,
          "X-KEY"       => self.jason_key,
          "X-CLASS"     => self.class.name,
          "X-PARENT"    => @parent.jason_key,
          "X_LIST"      => @attachment_name
          #also want to add the eTag here!
          #may also want to add any other indexable fields that the user specifies?
      }

      resp = RestClient.post to_url, contents, post_headers

      if resp.code == 201
        @__jason_state = :stale
        true
      else
        false
      end
    end
  end
end
