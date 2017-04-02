#encoding: utf-8


# Module StringHelper
module StringHelper

  ##
  # The method helps to replace problematic chars from string to be used as part of file path.
  #
  # @param [String] path
  #
  # @return [String] path
  def self.get_clear_file_path(path)
    path.to_s.gsub(/[:\/\.\*#]/, '_')
  end

  ##
  # The method helps to get snake case string from camel case one.
  #
  # @param [String] path
  #
  # @return [String] snake_cased_string
  def self.get_snake_case(string)
    string.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr('-', '_').
        downcase
  end

end