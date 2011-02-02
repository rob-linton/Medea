require 'spec_helper'

describe "Jason Blob" do

  class Update < Medea::JasonObject
    has_attachment :avatar
  end

  before :each do
    @update = Update.new
  end

  after :each do
    @update.delete!
  end

  it "should be persisted" do
    @update.avatar = "Here's some text!"
    @update.save!
    u2 = Update.get_by_key(@update.jason_key)
    u2.avatar.contents.should eq("Here's some text!")
    u2.avatar.contents.size.should eq("Here's some text!".size)
  end

  it "should work for larger images" do
    f = File.new("./spec/test.jpg", "r")
    @update.avatar = f
    @update.save!
    Update.get_by_key(@update.jason_key).avatar.contents.size.should eq(f.size)
  end
end