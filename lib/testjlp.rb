$: << "~/Projects/Medea/lib"
require 'medea'

class Person < Medea::JasonObject
  has_many :followees, Person
end

p = Person.get_by_key "p6c75c02f-ed93-4ee8-9746-3603e915be23"

puts p.followees.to_url
puts p.followees.count

puts "Let's make a new person!"

p1 = Person.new
puts "Name?"
p1.name = gets.strip
if p1.name != ""
  puts "Saving..."
  p1.save!

  puts "Making #{p.name} follow #{p1.name}..."
  p.followees.add! p1
end
puts "Done!"
list = p.followees
puts "#{p.name} now following #{list.count} users:"
list.each do |f|
  puts " - #{f.jason_key}: #{f.name}\n"
end
