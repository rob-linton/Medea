$: << "~/Projects/Medea/lib"
require 'medea'

class Message < Medea::JasonObject; end

class User < Medea::JasonObject
  owns_many :messages, Message
  has_many :followees, User
end

u1 = User.new
u1.name = "Fred"
u1.save!

u2 = User.new
u2.name = "George"
u2.save!

u1.followees.add! u2
u1.followees.add! (User.get_by_key "p438639000")
u1.followees.add! u1

m1 = Message.new
m1.from = u2.name
m1.message = "Hello! This is George"
u2.messages.add! m1

m3 = Message.new
m3.from = u1.name
m3.message = "George sent me here, hope it's fun!"
u1.messages.add! m3

m2 = Message.new
m2.from = u2.name
m2.message = "Man, this is a long day!"
u2.messages.add! m2

puts "#{u2.name} has posted #{u2.messages.count} messages"

puts "#{u1.name} is following #{u1.followees.count} users"
puts "#{u1.name}'s timeline has #{u1.followees.messages.count} messages in it"

u1.followees.messages.each do |m|
  puts "#{m.from}:"
  puts "      #{m.message}"
end