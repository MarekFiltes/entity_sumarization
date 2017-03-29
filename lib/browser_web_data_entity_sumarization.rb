#encoding: utf-8
require 'sparql/client'
require 'benchmark'
require 'json'

module BrowserWebData
  module EntitySumarization

  end
end

Dir.glob(File.dirname(__FILE__) + '/utils/*.rb').each { |file| require file }
Dir.glob(File.dirname(__FILE__) + '/config/*.rb').each { |file| require file }

# Require all gem scripts by their relative names
Dir[File.dirname(__FILE__) + '/browser_web_data_entity_sumarization/**/*.rb'].each do |file|
  require(file.gsub('\\', '/').split('/lib/').last[0..-4])
end





