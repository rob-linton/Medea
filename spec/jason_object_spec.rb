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

  it "should provide access to its timestamp from JasonDB" do
    @user.save!
    @user.jason_timestamp.should_not be_nil
    t = @user.jason_timestamp
    @user.name = "Smithy"
    @user.save!
    user2 = User.get_by_key(@user.jason_key)
    user2.jason_timestamp.should_not be_nil
    user2.jason_timestamp.should be > t
  end

  it "should post location information properly" do
    @user.geohash = "r1r0rshvpuxg"
    RestClient.should_receive(:post).with(anything(), anything(), hash_including("X-GEOHASH" => "r1r0rshvpuxg")).and_return(DummyResponse.new)
    @user.save!
    @user.latitude, @user.longitude = [-37.901949, 145.180206]
    RestClient.should_receive(:post).with(anything(), anything(), hash_including("X-LATITUDE" => -37.901949,
                                                                                 "X-LONGITUDE" => 145.180206)).and_return(DummyResponse.new)
    @user.save!
  end

  it "should load location information properly" do
    @user.geohash = "r1r0rshvpuxg"
    @user.latitude, @user.longitude = [-37.901949, 145.180206]
    @user.save!
    retrieved_user = User.get_by_key(@user.jason_key)
    retrieved_user.geohash.should eq(@user.geohash)
    retrieved_user.latitude.should eq(@user.latitude)
    retrieved_user.longitude.should eq(@user.longitude)
  end

  it "should provide it's public (insecure) url" do
    #should return url non-https, and with no user/password
    (@user.to_url :public).should match(/http:\/\/rest.jasondb.com/)
    @user.to_public_url.should eq(@user.to_url :public)
  end

  it "should post security information properly" do
    @user.add_public :GET, :POST
    RestClient.should_receive(:post).with(anything(), anything(), hash_including("X-PUBLIC" => "GET,POST")).and_return(DummyResponse.new)
    @user.save!
  end

  it "should only post valid verbs" do
    @user.add_public :GET, :FAKEVERB
    RestClient.should_receive(:post).with(anything(), anything(), hash_including("X-PUBLIC" => "GET")).and_return(DummyResponse.new)
    @user.save!
  end

  it "should load security information properly" do
    @user.set_public :GET, :POST
    @user.save!
    retrieved_user = User.get_by_key @user.jason_key
    (retrieved_user.send(:instance_variable_get, :@public)).should eq(["GET", "POST"])
  end
end