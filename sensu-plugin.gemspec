# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__)) + '/lib/sensu-plugin'

Gem::Specification.new do |s|
  s.name                  = 'sensu-plugin'
  s.version               = Sensu::Plugin::VERSION
  s.platform              = Gem::Platform::RUBY
  s.authors               = ['Decklin Foster', 'Sean Porter']
  s.email                 = ['decklin@red-bean.com', 'portertech@gmail.com']
  s.homepage              = 'https://github.com/sensu-plugins/sensu-plugin'
  s.summary               = 'Sensu Plugins'
  s.description           = 'Plugins and helper libraries for Sensu, a monitoring framework'
  s.license               = 'MIT'
  s.has_rdoc              = false
  s.require_paths         = ['lib']
  s.executables           = Dir.glob('bin/**/*.rb').map { |file| File.basename(file) }
  s.files                 = Dir.glob('{bin,lib}/**/*')
  s.test_files            = Dir['test/*.rb']
  s.required_ruby_version = '>= 2.3'

  s.add_dependency 'json',       '< 3.0.0'
  s.add_dependency 'mixlib-cli', '~> 1.5'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop', '~> 0.49.0'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'webmock'
end
