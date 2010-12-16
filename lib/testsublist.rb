$: << "C:/Users/michaelj.LOGICALTECH/Documents/My Dropbox/Projects/Medea/lib"
require 'medea'

class Message < Medea::JasonObject; end

class User < Medea::JasonObject
  owns_many :messages, Message
  has_many :followees, User
end

#load up Terence
u = User.get_by_key "p802337000"

puts "#{u.name} is following #{u.followees.count} users"

puts "#{u.name}'s timeline:"
u.followees.messages.each do |m|
  puts " - #{m.message}"
end