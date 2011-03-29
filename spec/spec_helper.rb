$: << File.join(File.dirname(__FILE__), '/../lib')
require 'rspec'
require 'rspec/mocks'
require 'medea'

class Message < Medea::JasonObject
end

ENV["jason_user"] = "michael"
ENV["jason_topic"] = "medea-test"
ENV["jason_password"] = "password"

class User < Medea::JasonObject
  has_location
  has_many :followees, User
  owns_many :messages, Message
end

class DummyResponse
  def code
    201
  end
  def headers
    {:Etag => "sometag",
     :timestamp => "12345678"}
  end
end
