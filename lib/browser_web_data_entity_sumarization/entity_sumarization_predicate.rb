# encoding: utf-8

module BrowserWebData

  module EntitySumarization


    class Predicate
      include BrowserWebData::EntitySumarizationConfig

      ###
      # The method helps identify unimportant predicate by constants.
      #
      # @param [String] property
      #
      # @return [TrueClass, FalseClass] result
      def self.unimportant?(property)
        property = property.to_s
        NO_SENSE_PROPERTIES.include?(property) || COMMON_PROPERTIES.include?(property)
      end

    end

  end

end