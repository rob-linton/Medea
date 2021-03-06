#This module allows for an attribute to be defined on a superclass and carry down into sub-classes with its default.
#Taken from http://railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby/

module ClassLevelInheritableAttributes
  def self.included(base)
    base.extend(ClassMethods)    
  end
  
  module ClassMethods
    def inheritable_attributes(*args)
      #for some reason, in rails, @inheritable_attributes is set to be an empty hash here...
      #check for this strange case and account for it.
      @inheritable_attributes = [:inheritable_attributes] if @inheritable_attributes == {} ||
                                                             @inheritable_attributes == nil
      @inheritable_attributes += args
      args.each do |arg|
        class_eval %(
          class << self; attr_accessor :#{arg} end
        )
      end
      @inheritable_attributes
    end
    
    def inherited(subclass)
      @inheritable_attributes.each do |inheritable_attribute|
        instance_var = "@#{inheritable_attribute}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
    end
  end
end