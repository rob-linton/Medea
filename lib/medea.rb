
module Medea
  require 'rubygems'
  require 'medea/version'
  require 'medea/inheritable_attributes'
  require 'medea/active_model_methods'
  require 'medea/list_properties'
  require 'medea/jasonobject'
  require 'medea/jasondeferredquery'
  require 'medea/jasonlistproperty'
  require 'medea/jasondb'

  if defined?(Rails)
    LOGGER = Rails.logger
  else
    require 'medea/dummy_logger'
    LOGGER = DummyLogger.new
  end
end