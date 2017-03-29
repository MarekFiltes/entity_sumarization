$:.push File.expand_path('../lib', __FILE__)

lp = File.expand_path(File.dirname(__FILE__))
unless $LOAD_PATH.include?(lp)
  $LOAD_PATH.unshift(lp)
end

require 'browser_web_data_entity_sumarization/version'

Gem::Specification.new do |s|
  s.name          = 'browser_web_data_entity_sumarization'
  s.version       = EntitySumarization::VERSION

  s.require_paths = %w(lib results)
  s.files         = Dir['lib/**/*.*']

  s.summary       = 'Tool for entity sumarization.'

  s.author        = 'Marek Filteš'
  s.email         = 'marek.filtes@gmail.com'

  # s.description   = '< description >'
  # s.homepage      = '< vendor homepage >'
  # s.license       = '< library licence >'

  s.add_dependency('sparql-client', '2.1.0')

end
