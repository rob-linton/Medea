module JasonObjectMetaProperties
  def self.included(base)
    base.extend(MetaProperties)
  end
  
  module MetaProperties
    def _class_options &block
      self.send(:class_variable_set, :@@opts, {}) unless self.send(:class_variable_defined?, :@@opts)
      opts = self.send(:class_variable_get, :@@opts)
      yield opts
      self.send(:class_variable_set, :@@opts, opts)
    end

    def create_member_list list_name, list_class, list_type
      _class_options do |o|
        o[:lists] ||= {}
        o[:lists][list_name] = [list_class, list_type]
      end

      define_method(list_name) do
        #puts "Looking at the #{list_name.to_s} list, which is full of #{list_type.name}s"
        Medea::JasonListProperty.new self, list_name, list_class, list_type
      end
    end

    def has_many list_name, list_class
      create_member_list list_name, list_class, :reference
    end

    def owns_many list_name, list_class
      create_member_list list_name, list_class, :value

      #also modify the items in the list so that they know that they're owned
      #list_type.class_variable_set :@@owner, self
      list_class.owned = true
    end

    def has_attachment attachment_name
      _class_options do |o|
        o[:attachments] ||= []
        o[:attachments] << attachment_name
        o[:attachments].uniq!
      end
    end

    def has_location
      _class_options do |o|
        o[:located] = true
       end
    end

    #sets the default public/private status for objects in this class
    def public *args
      verbs = [:GET, :POST, :PUT, :DELETE]
      args.reject! do |i|
        not verbs.include? i
      end
      _class_options do |o|
        o[:public] ||= []
        o[:public] << args
        o[:public].flatten!
        o[:public].uniq!
      end
    end

    def key_field field_name
      #this field must be present to save, and it must be unique
      _class_options do |o|
        o[:key_fields] ||= []
        o[:key_fields] << field_name
        o[:key_fields].uniq!
      end
    end
  end
end