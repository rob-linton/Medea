require "spec_helper"

describe "Deferred Query" do

  it "should be enumerable" do
    for u in User.all

    end
  end
end