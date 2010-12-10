$: << "C:/Users/michaelj.LOGICALTECH/Documents/My Dropbox/Projects/Medea/lib"
require 'medea'

class Person < Medea::JasonObject
end

class Company < Medea::JasonObject
end

puts "Lets make a person!"
p = Person.new
puts "Name?"
p.name = gets.strip
puts "Age?"
p.age = gets.strip.to_i
puts "OK - Saving"
p.save!

puts "", "Lets make a company!"
c = Company.new
puts "Name?"
c.name = gets.strip
puts "Address?"
c.address = gets.strip
puts "OK - Saving"
c.save!

puts "", "Making #{p.name} a member of #{c.name}"
p.make_member_of(c)
puts "OK - Saving"

puts "", "Now querying for Persons that are members of #{c.name}"
r = Person.members_of(c)
puts "Got:"
r.each do |p|
  puts p.name
end