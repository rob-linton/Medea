module JasonObjectListProperties
  def self.included(base)
    base.extend(MetaListProperties)
  end
  
  module MetaListProperties
    def create_member_list list_name, list_class, list_type
      list = {}
      list = self.class_variable_get :@@lists if self.class_variable_defined? :@@lists
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
  end
end