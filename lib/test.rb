$: << "~/Projects/Medea/lib"
require 'rubygems'
require 'medea'

class Person < Medea::JasonObject
end

mikey = Person.new
puts "state: #{mikey.jason_state}"
mikey.name = "Michael"
mikey.age = 21
mikey.location = {:longitude => -30.123213, :latitude => 130.1231458}
puts mikey.to_json
mikey.save!

puts "state: #{mikey.jason_state}"

puts "Changing name => Bob"
mikey.name = "Bob"

puts "state: #{mikey.jason_state}"
puts mikey.to_json
mikey.save!
puts "state: #{mikey.jason_state}"

puts "Enter a Person key to retrieve: "
id = gets.strip

person = Person.new id
puts person.to_json
