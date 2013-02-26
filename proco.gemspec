# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proco/version'

Gem::Specification.new do |gem|
  gem.name          = "proco"
  gem.version       = Proco::VERSION
  gem.authors       = ["Junegunn Choi"]
  gem.email         = ["junegunn.c@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = "https://github.com/junegunn/proco"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'lps', '~> 0.1.1'
  gem.add_runtime_dependency 'option_initializer', '~> 1.1.0'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'parallelize'
end
