
# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "medea/version"

Gem::Specification.new do |s|
  s.name        = "medea"
  s.version     = Medea::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Jensen"]
  s.email       = ["michaelj@jasondb.com"]
  s.homepage    = ""
  s.summary     = %q{Simple wrapper for persisting objects to JasonDB}
  s.description = %q{Simple wrapper for persisting objects to JasonDB}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "json"
  s.add_dependency "rest-client"
  s.add_dependency "uuidtools"
  s.add_dependency "pr_geohash"

  s.add_development_dependency "rspec"
end
