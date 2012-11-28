# -*- encoding: utf-8 -*-
require File.expand_path('../lib/object_momma/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nathan Ladd", "Joshua Flanagan"]
  gem.email         = ["nathan@peopleadmin.com"]
  gem.description   = %q{object_momma is an Object Mother implementation in ruby}
  gem.summary       = %q{object_momma is an Object Mother implementation in ruby; it is designed to facilitate complex data setup for acceptance tests.}

  gem.homepage      = "https://github.com/PeopleAdmin/object_momma"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "object_momma"
  gem.require_paths = ["lib"]
  gem.version       = ObjectMomma::VERSION

  gem.add_development_dependency 'rspec'
end
