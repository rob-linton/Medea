module JasonObjectMetaProperties
  def self.included(base)
    base.extend(MetaProperties)
  end
  
  module MetaProperties
    def create_member_list list_name, list_class, list_type
      list = {}
      list = self.send(:class_variable_get, :@@lists) if self.class_variable_defined? :@@lists
      list[list_name] = [list_class, list_type]
      self.send(:class_variable_set, "@@lists", list)

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
      attachments = []
      attachments = self.send(:class_variable_get, :@@attachments) if self.class_variable_defined? :@@attachments
      attachments << attachment_name
      attachments.uniq!
      self.send(:class_variable_set, "@@attachments", attachments)
    end

    def key_field field_name
      #this field must be present to save, and it must be unique
      self.send(:class_variable_set, :@@key_field, field_name)
    end
  end
end