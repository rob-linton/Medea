require "spec_helper"

describe "Deferred Query" do

  before :all do
    @userlist = []
    10.times do |i|
      u = User.new
      u.name = "Person#{i}"
      u.save!
      @userlist << u
    end
  end

  after :all do
    @userlist.each do |u|
      u.delete!
    end
  end

  it "should be enumerable" do
    for u in User.all
    end
  end

  it "should be able to be limited to a certain number of results" do
    u = User.all
    u.limit = 5
    u.count.should be == 5

    u = User.all :limit => 4
    u.count.should be == 4
  end

  it "should be able to fetch those since a particular time" do
    u = User.all[10]
    User.all(:since => u.jason_timestamp).each do |i|
      i.jason_timestamp.should be >= u.jason_timestamp
    end
  end

  it "should return the last element" do
    u = User.all
    u.last.should eq(u[-1])
  end

  it "should return the first element" do
    u = User.all
    u.first.should eq(u[0])
  end
end