require "rspec"

describe "Medea Framework" do
  it "should install templates if they aren't there" do
    resp = mock("Response").as_null_object
    RestClient.stub(:get).and_return resp
    RestClient.stub(:post).and_return resp
    resp.stub(:code).and_return 404
    resp.stub(:headers).and_return({})

    RestClient.should_receive(:post)
    Medea::setup_templates
  end

  it "should install templates if the template version is newer" do
    resp = mock("Response").as_null_object
    RestClient.stub(:get).and_return resp
    RestClient.stub(:post).and_return resp
    resp.stub(:code).and_return 200
    resp.stub(:headers).and_return({:http_x_version => "0.1.0"}) 

    RestClient.should_receive(:post)
    Medea::setup_templates
  end

  it "should not install templates if they are up to date" do
    resp = mock("Response").as_null_object
    RestClient.stub(:get).and_return resp
    RestClient.stub(:post).and_return resp
    resp.stub(:code).and_return 200
    resp.stub(:headers).and_return({:http_x_version => Medea::TEMPLATE_VERSION})

    RestClient.should_not_receive(:post)
    Medea::setup_templates
  end

  it "should raise an error if the remote version is newer" do
    resp = mock("Response").as_null_object
    RestClient.stub(:get).and_return resp
    RestClient.stub(:post).and_return resp
    resp.stub(:code).and_return 200
    #version 999.0.0 is pretty much guaranteed to always be a newer version
    resp.stub(:headers).and_return({:http_x_version => "999.0.0"})

    RestClient.should_not_receive(:post)
    expect{Medea::setup_templates}.to raise_error(RuntimeError)
  end

end