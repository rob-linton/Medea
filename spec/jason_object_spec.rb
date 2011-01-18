require 'spec_helper'

describe "JasonObject" do
  before :each do
    @user = User.new
  end

  after :each do
    @user.delete!
  end

  it "should be comparable to other JasonObjects" do
    @user.save!
    (@user == User.new).should eq(false)
    (@user == @user).should eq(true)
    (@user == User.get_by_key(@user.jason_key, :lazy)).should eq(true)
    (@user == User.get_by_key(@user.jason_key)).should eq(true)
    (@user == "Hello world?").should eq(false)
    (@user == @user.jason_key).should eq(false)
  end

  it "should be persistable" do
    @user.name = "Freddy"
    @user.save!

    @user.jason_state.should eq(:stale)

    retrieved_user = User.get_by_key @user.jason_key
    retrieved_user.name.should eq(@user.name)
  end

  it "should track its state" do
    @user.jason_state.should eq(:new)
    @user.save!
    @user.name = "Freddy"
    @user.jason_state.should eq(:dirty)
    @user.save!
    @user.jason_state.should eq(:stale)

    retrieved_user = User.get_by_key @user.jason_key, :lazy
    retrieved_user.jason_state.should eq(:ghost)
    retrieved_user.name
    retrieved_user.jason_state.should eq(:stale)
  end

  it "should not load deleted objects" do
    u = User.new
    u.name = "Michael"
    u.save!
    u.delete!
    User.all.each do |usr|
      usr.should_not eq(u)
    end
  end

  it "should be initialisable with a hash" do
    @user = User.new({:name => "Jimmy", :age => 31})
    @user.name.should eq("Jimmy")
    @user.age.should eq(31)
  end

  it "should be updateable with update_attributes" do

    field_hash = {:name => "Robert",
                  :age => 25}
    @user.name = "Fred"
    @user.age = 20

    @user.stub(:save).and_return true
    @user.should_receive :save
    (@user.update_attributes field_hash).should eq(true)

    @user.name.should eq(field_hash[:name])
    @user.age.should eq(field_hash[:age])
  end

  it "should pass the result of save back through update_attributes" do
    @user.stub(:save).and_return true
    (@user.update_attributes({})).should eq(true)

    @user.stub(:save).and_return false
    (@user.update_attributes({})).should eq(false)
  end
end