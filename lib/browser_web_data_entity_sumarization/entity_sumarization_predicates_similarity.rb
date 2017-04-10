# encoding: utf-8

module BrowserWebData

  module EntitySumarization


    class PredicatesSimilarity
      include BrowserWebData::EntitySumarizationConfig

      def initialize(results_dir_path, console_output = false)
        @results_dir_path = results_dir_path
        @console_output = console_output

        @query = SPARQLRequest.new

        load_identical_predicates
        load_different_predicates
      end

      ###
      # The method return key of identical predicates
      #
      # @param [Array<String>] predicates
      #
      # @return [String] key
      def self.get_identical_key(predicates)
        "<#{predicates.join('><')}>" if predicates && !predicates.empty?
      end

      ###
      # The method return identical predicates by key
      #
      # @param [String] key
      #
      # @return [Array<String>] predicates
      def self.parse_identical_key(key)
        key.to_s.scan(SCAN_REGEXP[:identical_key]).reduce(:+)
      end

      def identify_identical_predicates(properties, identical_limit = IDENTICAL_PROPERTY_LIMIT)
        @temp_counts ||= {}

        combinations = properties.combination(2).to_a

        combinations.each { |values|


          already_mark_same = find_identical(values)
          already_mark_different = find_different(values)

          if already_mark_same.nil? && already_mark_different.nil?

            # in case of dbpedia ontology vs. property
            # automatically became identical
            unless try_auto_identical(values)

              unless @temp_counts[values[0]]
                @temp_counts[values[0]] = @query.get_count_of_identical_predicates(values[0])
              end

              unless @temp_counts[values[1]]
                @temp_counts[values[1]] = @query.get_count_of_identical_predicates(values[1])
              end

              x = @temp_counts[values[0]]
              y = @temp_counts[values[1]]
              z = @query.get_count_of_identical_predicates(values)

              identical_level = z / [x, y].max

              if identical_level >= identical_limit
                puts "     - result[#{identical_level}] z[#{z}] x[#{x}] y[#{y}] #{values.inspect}" if @console_output
                add_identical(values)
              else
                add_different(values)
              end
            end

          end
        }

      end

      ###
      # The method helps to recognize if is already marked as identical properties
      #
      # @param [Array<String>, String] value
      #
      # @return [String, NilClass]
      def find_identical(value)
        raise RuntimeError.new('No support identify identical for more than 2 predicates.') if value.is_a?(Array) && value.size >2

        case value
          when Array
            @identical_predicates.find { |p| p[value[0]] && p[value[1]] }
          else
            value = value.to_s
            @identical_predicates.find { |p| p[value] }
        end
      end

      ###
      # The method helps to recognize if is already marked as different properties
      #
      # @param [Array<String>, String] value
      #
      # @return [String, NilClass]
      def find_different(value)
        raise RuntimeError.new('No support identify identical for more than 2 predicates.') if value.is_a?(Array) && value.size >2

        key = case value
                when Array
                  @different_predicates.find { |p| p[value[0]] && p[value[1]] }
                else
                  value = value.to_s
                  @different_predicates.find { |p| p[value] }
              end

        PredicatesSimilarity.parse_identical_key(key)
      end

      def add_identical(values)
        values = values.map { |p| p.to_s }.uniq.sort
        group_key = PredicatesSimilarity.get_identical_key(values)

        unless @identical_predicates.include?(group_key)
          @identical_predicates << group_key
          store_identical_properties
        end
      end

      def add_different(values)
        values = values.map { |p| p.to_s }.uniq.sort
        group_key = PredicatesSimilarity.get_identical_key(values)

        unless @different_predicates.include?(group_key)
          @different_predicates << group_key

          @new_diff_counter ||= 0
          @new_diff_counter += 1

          if @new_diff_counter > 100
            store_different_predicates
            @new_diff_counter = 0
          end

        end
      end

      def try_auto_identical(values)
        group_key = PredicatesSimilarity.get_identical_key(values)

        temp = values.map { |val| val.split('/').last }.uniq
        if temp.size == 1 && group_key['property/'] && group_key['ontology/']
          add_identical(values)
          true
        else
          false
        end
      end


      ###
      # The method helps to reduce identical predicates by join of common predicate
      def reduce_identical
        new_identical = []

        @identical_predicates.each { |key|
          values = PredicatesSimilarity.parse_identical_key(key)
          next if new_identical.find { |v| !(v & values).empty? }

          ## find nodes with values predicates
          values = recursive_find_identical(key, values)

          new_identical << values.uniq.sort
        }

        @identical_predicates = new_identical.map { |v| PredicatesSimilarity.get_identical_key(v) }

        store_identical_properties
      end

      def recursive_find_identical(keys, values)
        keys = [keys] unless keys.is_a?(Array)

        @identical_predicates.each { |this_key|
          next if keys.include?(this_key)
          temp = PredicatesSimilarity.parse_identical_key(this_key)

          unless (temp & values).empty?
            keys << this_key
            return recursive_find_identical(keys, (values + temp).uniq)
          end
        }

        values
      end


      private


      def load_identical_predicates
        unless @identical_predicates
          file_path = "#{@results_dir_path}/identical_predicates.json"
          @identical_predicates = ensure_load_json(file_path, [])
        end
      end

      def load_different_predicates
        unless @different_predicates
          file_path = "#{@results_dir_path}/different_predicates.json"
          @different_predicates = ensure_load_json(file_path, [])
        end
      end

      def store_identical_properties
        File.write("#{@results_dir_path}/different_predicates.json", JSON.generate(@different_predicates))
      end

      def store_different_predicates
        File.write("#{@results_dir_path}/different_predicates.json", JSON.generate(@different_predicates))
      end

    end

  end

end