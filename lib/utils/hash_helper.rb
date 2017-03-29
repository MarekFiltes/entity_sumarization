#encoding: utf-8


# Module HashHelper
module HashHelper

  ##
  # The method helps to get new sorted hash by key.
  #
  # @param [Hash] hash Input hash which will be sorted.
  # @param [Symbol, String] type Type of sorting, default is asc as ascending. One of [:asc, :desc]
  #
  # @return [Hash] sorted_hash
  def self.get_sorted(hash, type = :asc)
    hash = {} unless hash
    case type.to_s.downcase.to_sym
      when :asc
        Hash[hash.sort]
      when :desc
        Hash[hash.sort{|a,b| a<=>b}]
      else
        hash
    end
  end

  ##
  # The method recursively symbolizes keys of hash.
  #
  # @param [Hash, Enumerable] input_value Data to by symbolized.
  # @return [Hash, Enumerable] Symbolized data.
  def self.recursive_symbolize_keys(input_value)
    case input_value
      when Hash
        Hash[
            input_value.map do |k, v|
              [k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v)]
            end
        ]
      when Enumerable
        input_value.map { |v| recursive_symbolize_keys(v) }
      else
        input_value
    end
  end

  ##
  # The method recursively unsymbolizes keys of hash.
  #
  # @param [Hash, Enumerable] input_value Data to by symbolized.
  # @return [Hash, Enumerable] Symbolized data.
  def self.recursive_unsymbolize_keys(input_value)
    case input_value
      when Hash
        Hash[
            input_value.map do |k, v|
              [k.respond_to?(:to_s) ? k.to_s : k, recursive_unsymbolize_keys(v)]
            end
        ]
      when Enumerable
        input_value.map { |v| recursive_unsymbolize_keys(v) }
      else
        input_value
    end
  end


  def self.recursive_map_keys(data)
    data.map{|k,v|
      if v.is_a?(Hash) && !v.empty?
        inner_array = recursive_map_keys(v)
      else
        inner_array = []
      end

      [k] + inner_array
    }.reduce(:+)
  end

end