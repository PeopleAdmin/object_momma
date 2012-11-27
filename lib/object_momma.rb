require 'yaml'

require 'object_momma/class_attributes'

require 'object_momma/builder'
require 'object_momma/config'
require 'object_momma/child'
require 'object_momma/module_methods'
require 'object_momma/version'

module ObjectMomma
  BadChildIdentifier     = Class.new(StandardError)
  BadSerializer          = Class.new(StandardError)
  NotPersisted           = Class.new(StandardError)
  ObjectExists           = Class.new(StandardError)
  ObjectNotFound         = Class.new(StandardError)
  SubclassNotImplemented = Class.new(StandardError)

  self.extend(ObjectMomma::ModuleMethods)
  self.extend(ObjectMomma::Config)
end
