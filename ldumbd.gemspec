lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ldumbd/version'

Gem::Specification.new do |spec|
  spec.name          = 'ldumbd'
  spec.version       = Ldumbd::VERSION
  spec.author        = 'Sebastian Boehm'
  spec.email         = 'sebastian@sometimesfood.org'

  spec.summary       = %q{A simple, self-contained LDAP server}
  spec.homepage      = 'https://github.com/sometimesfood/ldumbd'
  spec.license       = 'MIT'
  spec.description   = <<EOS
Ldumbd is a simple, self-contained read-only LDAP server that uses
PostgreSQL, MySQL/MariaDB or SQLite as a back end.
EOS

  spec.files         = `git ls-files -z`.split("\0") &
    Dir['config.yml.sample',
        'Gemfile',
        'ldumbd.gemspec',
        'LICENSE',
        'NEWS',
        'Rakefile',
        'README.md',
        'TODO.org',
        '{bin,contrib,db,lib,spec}/**/*']
  spec.executables   = ['ldumbd']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'ruby-ldapserver', '~> 0.5.0'
  spec.add_dependency 'sequel', '~> 4.8.0'

  spec.add_development_dependency 'sqlite3', '~> 1.3.9'
  spec.add_development_dependency 'pg', '~> 0.17.1'
  spec.add_development_dependency 'mysql2', '~> 0.3.15'
  spec.add_development_dependency 'rake', '~> 10.1.1'
  spec.add_development_dependency 'minitest', '~> 5.3.0'
end
