# encoding: utf-8

###
# Core project module
module BrowserWebData

  ###
  # Project logic module
  module EntitySumarization

    ###
    # The class include methods to identify identical predicates
    class PredicatesSimilarity
      include BrowserWebData::EntitySumarizationConfig

      ###
      # The method create new instance of PredicatesSimilarity class.
      #
      # @param [String] results_dir_path
      # @param [Float] identical_limit Define minimal identical percent rate of predicates to mark as identical.
      # @param [TrueClass, FalseClass] console_output Allow puts info to console. Default is false.
      def initialize(results_dir_path, identical_limit = IDENTICAL_PROPERTY_LIMIT, console_output = false)
        @results_dir_path = results_dir_path
        @console_output = console_output
        @identical_limit = identical_limit

        @query = SPARQLRequest.new

        load_identical_predicates
        load_different_predicates
        load_counts
      end

      ###
      # The method return key of identical predicates
      #
      # @param [Array<String>] predicates
      #
      # @return [String] key
      def self.get_key(predicates)
        predicates = [predicates] unless predicates.is_a?(Array)
        "<#{predicates.sort.join('><')}>" if predicates && !predicates.empty?
      end

      ###
      # The method return identical predicates by key
      #
      # @param [String] key
      #
      # @return [Array<String>] predicates
      def self.parse_key(key)
        key.to_s.scan(SCAN_REGEXP[:identical_key]).reduce(:+)
      end

      ###
      # The method verify every combination of two predicates.
      # Method store identify combination in two files identical_predicates.json and different_predicates.json
      # files contains Array of combination keys.
      # Given predicates count are is reduced to #IMPORTANCE_TO_IDENTIFY_MAX_COUNT (250)
      #
      # @param [Array<String>] predicates
      def identify_identical_predicates(predicates, identical_limit = @identical_limit)
        combination = predicates.take(IMPORTANCE_TO_IDENTIFY_MAX_COUNT).map { |p| p.to_sym }.combination(2)
        times_count = combination.size / 10

        combination.each_with_index { |values, i|



          already_mark_same = find_identical(values)
          already_mark_different = find_different(values)

          if already_mark_same.nil? && already_mark_different.nil?

            # in case of dbpedia ontology vs. property
            # automatically became identical
            unless is_identical_property_ontology?(values)

              unless @counts[values[0]]
                @counts[values[0]] = @query.get_count_of_identical_predicates(values[0])
              end

              unless @counts[values[1]]
                @counts[values[1]] = @query.get_count_of_identical_predicates(values[1])
              end

              x = @counts[values[0]]
              y = @counts[values[1]]
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

          if @console_output && ( i == 0 || (i+1) % times_count == 0 )
            puts "#{Time.now.localtime} | #{(((i+1)/combination.size) * 100).round(2)}% | [#{(i+1)}/#{combination.size}]"
          end

        }

        store_counts
      end

      ###
      # The method helps to recognize if is already marked as identical properties
      #
      # @param [Array<String>, String] value
      #
      # @return [String, NilClass]
      def find_identical(value)
        raise RuntimeError.new('No support identify identical for more than 2 predicates.') if value.is_a?(Array) && value.size >2

        predicates_key = case value
                           when Array
                             value = value.map { |v| PredicatesSimilarity.get_key(v) }
                             @identical_predicates.find { |p|
                               p[value[0]] && p[value[1]]
                             }
                           else
                             value = PredicatesSimilarity.get_key(value)
                             @identical_predicates.find { |p|
                               p[value]
                             }
                         end

        PredicatesSimilarity.parse_key(predicates_key)
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
                  value = value.map { |v| PredicatesSimilarity.get_key(v) }
                  @different_predicates.find { |p| p[value[0]] && p[value[1]] }
                else
                  value = PredicatesSimilarity.get_key(value)
                  @different_predicates.find { |p| p[value] }
              end

        PredicatesSimilarity.parse_key(key)
      end

      ###
      # The method add new identical values to local storage.
      #
      # @param [Array<String>] values
      def add_identical(values)
        values = values.map { |p| p.to_s }.uniq.sort
        group_key = PredicatesSimilarity.get_key(values)

        unless @identical_predicates.include?(group_key)
          @identical_predicates << group_key
          store_identical_properties
        end
      end

      ###
      # The method add new different values to local storage.
      #
      # @param [Array<String>] values
      def add_different(values)
        values = values.map { |p| p.to_s }.uniq.sort
        group_key = PredicatesSimilarity.get_key(values)

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

      ###
      # The method helps to automatic identify identical properties
      # that means DBpedia property versus ontology predicates.
      #
      # @param [Array<String>] values
      #
      # @return [TrueClass, FalseClass] resuls
      def is_identical_property_ontology?(values)
        group_key = PredicatesSimilarity.get_key(values)

        temp = values.map { |val| val.to_s.split('/').last }.uniq
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
          values = PredicatesSimilarity.parse_key(key)
          next if new_identical.find { |v| !(v & values).empty? }

          ## find nodes with values predicates
          values = recursive_find_identical(key, values)

          new_identical << values.uniq.sort
        }

        @identical_predicates = new_identical.map { |v| PredicatesSimilarity.get_key(v) }

        store_identical_properties
      end

      ###
      # The method helps to collect identical chains.
      #
      # @param [Array<String>] keys Array of identical key items.
      # @param [Array<String>] values All values that is related to all keys.
      #
      # @return [Array<String>] all_find_values
      def recursive_find_identical(keys, values)
        keys = [keys] unless keys.is_a?(Array)

        @identical_predicates.each { |this_key|
          next if keys.include?(this_key)
          temp = PredicatesSimilarity.parse_key(this_key)

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

      def load_counts
        unless @counts
          file_path = "#{@results_dir_path}/counts.json"
          @counts = ensure_load_json(file_path, {})
        end
      end

      def store_identical_properties
        File.write("#{@results_dir_path}/identical_predicates.json", JSON.generate(@identical_predicates))
      end

      def store_different_predicates
        File.write("#{@results_dir_path}/different_predicates.json", JSON.generate(@different_predicates))
      end

      def store_counts
        File.write("#{@results_dir_path}/counts.json", JSON.generate(@counts))
      end


      def ensure_load_json(file_path, def_val, json_params = {})
        if File.exists?(file_path)
          file_data = File.read(file_path).force_encoding('utf-8')
          if file_data.size >= 2 # '[]'
            JSON.parse(file_data, json_params)
          else
            def_val
          end
        else
          def_val
        end
      end

    end

  end

end