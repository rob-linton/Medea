require "spec_helper"

describe "list properties" do
  before :all do
    @user_list = []
    @user = User.new
    @user_list << @user
    (1..4).collect do |i|
      other_user = User.new
      other_user.name = "Automaton #{i}"
      @user_list << other_user
      @user.followees.add! other_user
      m = Message.new
      m.message = "Hello world! #automaton"
      other_user.messages.add! m
    end

    ["Hello? #user", "Is this thing on? #user", "I love Mondays! #user"].each do |m|
      msg = Message.new
      msg.message = m
      @user.messages.add! msg
    end

  end

  after :all do
    @user_list.each do |user|
      user.messages.each do |m|
        user.remove! m, true
      end
      user.delete!
    end
  end

  it "should add a method to the class" do
    @user.respond_to?(:followees).should eq(true)
    @user.respond_to?(:messages).should eq(true)
    @user.respond_to?(:products).should eq(false)
  end

  it "should return a JasonListProperty" do
    @user.followees.is_a?(Medea::JasonListProperty).should eq(true)
    @user.messages.is_a?(Medea::JasonListProperty).should eq(true)
  end

  it "should resolve to objects" do
    @user.followees.each do |f|
      f.is_a?(Medea::JasonObject).should eq(true)
    end

    @user.messages.each do |m|
      m.is_a?(Medea::JasonObject).should eq(true)
      m.message.should include("#user")
    end
  end

  it "should resolve sub-lists" do
    @user.followees.messages.is_a?(Medea::JasonListProperty).should eq(true)
  end

  it "should resolve items in a sub-list as objects" do
    @user.followees.messages.each do |msg|
      msg.is_a?(Medea::JasonObject).should eq(true)
      msg.message.should include("#automaton")
    end
  end

  it "should count correctly" do
    @user.messages.count.should eq(3)
    @user.followees.messages.count.should eq(4)
    @user.followees.count.should eq(4)
  end
end