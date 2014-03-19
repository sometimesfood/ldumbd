lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ldumbd/version'

Gem::Specification.new do |spec|
  spec.name          = 'ldumbd'
  spec.version       = Ldumbd::VERSION
  spec.author        = 'Sebastian Boehm'
  spec.email         = 'sebastian@sometimesfood.org'
  spec.description   = %q{gem description}
  spec.summary       = %q{gem summary}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_dependency 'ruby-ldapserver', '~> 0.5.0'
  spec.add_dependency 'sequel', '~> 4.7.0'
  spec.add_dependency 'sqlite3', '~> 1.3.9'
  spec.add_development_dependency 'pg', '~> 0.17.1'
  spec.add_development_dependency 'mysql2', '~> 0.3.15'
  spec.add_development_dependency 'rake', '~> 10.0.4'
  spec.add_development_dependency 'bundler', '~> 1.3.5'
  spec.add_development_dependency 'net-ldap', '~> 0.3.1'
  spec.add_development_dependency 'minitest', '~> 5.3.0'
end
