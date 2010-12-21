$: << "C:/Users/michaelj.LOGICALTECH/Documents/My Dropbox/Projects/Medea/lib"
require 'medea'

class Message < Medea::JasonObject
end

class User < Medea::JasonObject
  owns_many :messages, Message
end

puts "Enter an id, or blank to make a new user:"
id = gets.strip
if id == ""
  u = User.new
  puts "User's name?"
  u.name = gets.strip

  puts "Saving"
  u.save!
else
  u = User.get_by_key id
  puts "#{u.name} has posted #{u.messages.count} messages"
end

while true
  puts "Enter a message (blank to stop):"
  message = gets.strip
  break if message == ""
  m = Message.new
  m.message = message
  m.from = u.name
  u.messages.add! m
end

puts "Fetching messages..."
u.messages.each do |e|
  puts " - #{e.message}\n"
end