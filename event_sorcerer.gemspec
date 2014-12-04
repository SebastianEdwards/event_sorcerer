# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_sorcerer/version'

Gem::Specification.new do |spec|
  spec.name          = 'event_sorcerer'
  spec.version       = EventSorcerer::VERSION
  spec.authors       = ['Sebastian Edwards']
  spec.email         = ['me@sebastianedwards.co.nz']
  spec.homepage      = 'https://github.com/SebastianEdwards/event_sorcerer'
  spec.summary       = %w(Generic event-sourcing scaffold)
  spec.description   = spec.summary

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'inch'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'invokr', '~> 0.9.6'
  spec.add_runtime_dependency 'timecop', '0.7.1'
  spec.add_runtime_dependency 'uber', '~> 0.0.11'
end
