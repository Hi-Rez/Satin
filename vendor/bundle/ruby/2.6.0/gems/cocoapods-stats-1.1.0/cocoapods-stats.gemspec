# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_stats/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-stats'
  spec.version       = CocoapodsStats::VERSION
  spec.authors       = ['Orta Therox', 'Samuel Giddins']
  spec.email         = ['orta.therox@gmail.com', 'segiddins@segiddins.me']
  spec.description   = 'Uploads statistics for Pod Analytics.'
  spec.summary       = 'Uploads installation version data to ' \
                       'stats.cocoapods.org to provide per-Pod analytics.'
  spec.homepage      = 'https://github.com/cocoapods/cocoapods-stats'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 10.0'
end
