# -*- encoding: utf-8 -*-
require File.expand_path('../lib/object_momma/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["ntl"]
  gem.email         = ["nathanladd@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "object_momma"
  gem.require_paths = ["lib"]
  gem.version       = ObjectMomma::VERSION

  gem.add_development_dependency 'rspec'
end
