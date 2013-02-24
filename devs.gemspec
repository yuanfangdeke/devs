# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'devs/version'

Gem::Specification.new do |gem|
  gem.name          = "devs"
  gem.version       = DEVS::VERSION.dup
  gem.authors       = ["Romain Franceschini"]
  gem.email         = ["franceschini.romain@gmail.com"]
  gem.description   = %q{DEVS}
  gem.summary       = %q{Discrete EVent system Specification}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency('pqueue', '~> 2.0.2')
  gem.add_dependency('redcard', '~> 1.0.0')

  gem.add_development_dependency('gnuplot', '~> 2.6.2')
  gem.add_development_dependency('minitest')
end
