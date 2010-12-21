require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "medea"
    s.summary = "Simple wrapper for persisting objects to JasonDB"
    s.email = "michaelj@jasondb.com"
    s.homepage = "https://github.com/rob-linton/Medea"
    s.description = "Simple wrapper for persisting objects to JasonDB"
    s.authors = ["Michael Jensen"]
    s.files = FileList["[A-Z]*", "{lib}/medea.rb", "{lib}/medea/*"]
    s.files.exclude '{lib}/test*'
    s.add_dependency 'json'
    s.add_dependency 'rest-client'
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

