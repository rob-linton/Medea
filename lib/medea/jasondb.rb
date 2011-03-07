module JasonDB
  #jason_url here doesn't include the http[s]:// part, but does include the domain and a trailing '/'
  #( so it's "rest.jasondb.com/<domain>/" )
  def JasonDB::db_auth_url mode=:secure
    if ENV.include? "jason_user"
      config = ENV
    elsif defined? Rails
      config = Rails.configuration.database_configuration[Rails.env]
    else
      raise "No configuration for JasonDB found!"
    end
    
    user = config["jason_user"]
    topic = config["jason_topic"]
    password = config["jason_password"]
    if config["jason_host"]
      host = config["jason_host"]
    else
      host = "rest.jasondb.com"
    end
    protocol = "http"
    if mode == :secure
      protocol << "s"
      "#{protocol}://#{user}:#{password}@#{host}/#{topic}/"
    else #mode == :public
      #TODO Remove the dummy "a:a" here...
      "#{protocol}://a:a@#{host}/#{topic}/"
    end
  end

end

module Medea
  def Medea::setup_templates url=nil
    template_dir = File.expand_path("./templates", File.dirname(__FILE__))
    name_pattern = /([A-Za-z]+)\.([a-z]+)/
    headers = {:content_type => 'text/plain',
               'X-VERSION' => TEMPLATE_VERSION}
    curr_version = TEMPLATE_VERSION.split "."
    base_url = url ? url : JasonDB::db_auth_url
    Dir.glob(File.expand_path(File.join(template_dir, "*.template"))).select do |file|
      #for each template, we need to post it to ..#{filename}:html_template
      file =~ name_pattern
      template_path = "#{base_url}..#{$1}:#{$2}"

      #but,check the version first...
      begin
        r = RestClient.get template_path
        if r.code == 200 && r.headers[:http_x_version]
          version = r.headers[:http_x_version].split(".")
          version.each_index do |i|
            if version[i] < curr_version[i]
              RestClient.post template_path, File.read(file), headers
              break
            elsif version[i] > curr_version[i]
              raise "The remote templates are newer than the local ones! Update your gem!"
            end
          end
          next
        end

      rescue RestClient::ResourceNotFound
        #do nothing, it just means that the templates aren't uploaded yet.
      end
      RestClient.post template_path, File.read(file), headers
    end
  end
end