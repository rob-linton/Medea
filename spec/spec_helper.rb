$: << File.join(File.dirname(__FILE__), '/../lib')
require 'rspec'
require 'rspec/mocks'
require 'medea'

class Message < Medea::JasonObject
end

class User < Medea::JasonObject
  has_many :followees, User
  owns_many :messages, Message
end

#mock the db url
module JasonDB
  def JasonDB::db_auth_url mode=:secure
    "https://michael:password@rest.jasondb.com/medea-test/"
  end
end