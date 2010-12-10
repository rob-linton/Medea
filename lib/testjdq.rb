$: << "C:/Users/michaelj.LOGICALTECH/Documents/My Dropbox/Projects/Medea/lib"
require 'medea'

puts "JDQ on Persons"
jdq = Medea::JasonDeferredQuery.new "Person"
Person.find_by_name("Michael").find_by_age("21")
puts jdq.to_url

puts "---------", "Filtering by name = \"Michael\""
jdq.find_by_name("Michael")
puts jdq.to_url
