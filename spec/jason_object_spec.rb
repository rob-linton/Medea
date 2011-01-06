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

  it "should track it's state" do
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
end