class Parent
  attr_accessor :id

  def initialize id
    self.id = "parent:#{id}"
  end
  
  def self.has_many list_name, list_type
    list = {}
    list = self.class_variable_get :@@lists if self.class_variable_defined? :@@lists
    list[list_name] = list_type
    self.class_variable_set :@@lists, list

    define_method list_name, do
      puts "Looking at #{self.id}'s #{list_name.to_s} list, which is full of #{list_type.name}s"
    end
  end

  def self.owns_many list_name, list_type
      self.has_many list_name, list_type

      #also modify the items in the list so that they know that they're owned
      list_type.class_variable_set :@@owner, self
    end
end

class Toy

end

class Child < Parent
  owns_many :toys, Toy
  has_many :friends, Child

  def initialize id
    self.id = "child:#{id}"
  end
end

class School < Parent
  has_many :children, Child

  def initialize id
    self.id = "school:#{id}"
  end
end

c = Child.new 123
puts "Child variables:"
c.class.class_variables.each do |k|
  puts "#{k} => #{c.class.class_variable_get k}"
end
c.toys

puts "Toy variables:"
Toy.class_variables.each do |k|
  puts "#{k} => #{Toy.class_variable_get k}"
end

s = School.new 321
#s.toys
puts "School variables:"
s.class.class_variables.each do |k|
  puts "#{k} => #{s.class.class_variable_get k}"
end
s.children