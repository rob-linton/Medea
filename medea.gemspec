# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{medea}
  s.version = "0.2.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Jensen"]
  s.date = %q{2010-12-29}
  s.description = %q{Simple wrapper for persisting objects to JasonDB}
  s.email = %q{michaelj@jasondb.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "README",
    "Rakefile",
    "VERSION",
    "lib/medea.rb",
    "lib/medea/inheritable_attributes.rb",
    "lib/medea/jasondb.rb",
    "lib/medea/jasondeferredquery.rb",
    "lib/medea/jasonlistproperty.rb",
    "lib/medea/jasonobject.rb",
    "lib/medea/list_properties.rb"
  ]
  s.homepage = %q{https://github.com/rob-linton/Medea}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Simple wrapper for persisting objects to JasonDB}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_runtime_dependency(%q<uuidtools>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<uuidtools>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<uuidtools>, [">= 0"])
  end
end

