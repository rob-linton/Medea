$: << "C:/Users/michaelj.LOGICALTECH/Documents/My Dropbox/Projects/Medea/lib"
require 'medea'

class Person < Medea::JasonObject
  def followees
    Medea::JasonListProperty.new Person, "followees", jason_key
  end
end

p = Person.get_by_key "p829093000"

puts p.followees.to_url
puts p.followees.count

puts "Let's make a new person!"

p1 = Person.new
puts "Name?"
p1.name = gets.strip

puts "Saving..."
p1.save!

puts "Making #{p.name} follow #{p1.name}..."
p.followees.add! p1

puts "Done!"
puts "#{p.name} now following #{p.followees.count} users"