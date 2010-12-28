$: << "~/Projects/Medea/lib"
require 'medea'

class Person < Medea::JasonObject
end

class Company < Medea::JasonObject
  has_many :employees, Person
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
c.employees.add! p
puts "OK - Saving"
p.save!

puts "", "Now querying for Persons that are members of #{c.name}"
r = c.employees
puts "Query: #{r.to_url}"
puts "Got #{r.count} items:"
r.each do |p|
  puts p.name
end