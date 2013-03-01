# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proco/version'

Gem::Specification.new do |gem|
  gem.name          = "proco"
  gem.version       = Proco::VERSION
  gem.authors       = ["Junegunn Choi"]
  gem.email         = ["junegunn.c@gmail.com"]
  gem.description   = %q{A lightweight asynchronous task executor service designed for efficient batch processing}
  gem.summary       = %q{A lightweight asynchronous task executor service designed for efficient batch processing}
  gem.homepage      = "https://github.com/junegunn/proco"

  gem.files         = `git ls-files`.split($/).reject { |f| f =~ %r[^viz/] }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'lps', '~> 0.1.1'
  gem.add_runtime_dependency 'option_initializer', '~> 1.1.3'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'parallelize'
end
