# encoding: utf-8

###
# Core project module
module BrowserWebData

  ###
  # Project logic module
  module EntitySumarization


    ###
    # The class include helper methods.
    # (todo definition of predicate instance)
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