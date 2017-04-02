# encoding: utf-8

module BrowserWebData

  module EntitySumarization

    class Statistic
      include BrowserWebData::EntitySumarizationConfig

      attr_reader :nif_file_path, :results_dir_path

      def initialize(nif_dataset_path, results_dir_path = '../../results')
        nif_dataset_path = nif_dataset_path.gsub('\\', '/')
        results_dir_path = results_dir_path.gsub('\\', '/').chomp('/')

        return false unless File.exists?(nif_dataset_path)
        return false unless File.exists?(results_dir_path)
        @nif_file_path = nif_dataset_path.gsub('\\', '/')
        @results_dir_path = results_dir_path.gsub('\\', '/').chomp('/')

        @query = BrowserWebData::SPARQLRequest.new
      end

      def create_new(params)
        params[:entities_types] = [params[:entities_types]] unless params[:entities_types].is_a?(Array)

        generate_statistics_from_nif(params[:entities_types], params[:entity_count], params[:demand_reload])

        params[:entities_types].each { |type|
          generate_knowledge_base(type, params[:best_score_count], params[:identity_identical_predicates])
        }
      end

      def get_best_ranked_resources(entities_type, count = 10)
        resources = {}
        entities_type = [entities_type] unless entities_type.is_a?(Array)

        entities_type.each { |type|
          top_ranked_entities = @query.get_resources_by_dbpedia_page_rank(type, count)

          top_ranked_entities.each { |solution|
            resources[solution.entity.value] = {type: type, rank: solution.rank.value.to_f}
          }
        }

        resources
      end

      def generate_statistics_from_nif(entities_type, count = 10, demand_reload = false)
        resources = get_best_ranked_resources(entities_type, count)

        resources = keep_unloaded(resources) unless demand_reload

        actual_resource_data = []
        lines_group = []

        begin
          time_start = Time.now
          nif_file = File.open(@nif_file_path, 'r')
          line = nif_file.readline

          until nif_file.eof?
            line = nif_file.readline

            if lines_group.size == 7
              # evaulate group (7 lines)
              this_resource_uri = parse_group_to_resource_uri(lines_group)

              if resources.keys.include?(this_resource_uri)
                # process group, is requested
                resource_uri = this_resource_uri
                actual_resource_data << parse_line_group(lines_group)

              elsif !actual_resource_data.empty?
                # resource changed, process actual_resource_data
                resource_hash = resources.delete(resource_uri)
                type = resource_hash[:type]

                this_time = (Time.now - time_start).round(2)
                puts "\n#{resource_uri}\n- nif found in #{this_time}\n- resources to find #{resources.size}"

                result_relations = find_relations(resource_uri, actual_resource_data, type)
                generate_result_file(resource_uri, type, result_relations, this_time)

                break if resources.empty?

                actual_resource_data = []
                time_start = Time.now
              end

              # start new group
              lines_group = [line]
            else

              # join line to group
              lines_group << line
            end

          end

        ensure
          nif_file.close if nif_file && !nif_file.closed?
        end
      end

      def refresh_statistics_in_files(entities_type, count = 10)
        resources = get_best_ranked_resources(entities_type, count)

        resources = keep_loaded(resources)

        resources.each { |resource_uri, resource_info|
          puts "_____ #{resource_uri} _____"
          begin
            o, n = update_nif_file_properties(resource_uri, resource_info[:type]) { |link|
              get_properties_by_link(resource_uri, link, resource_info[:type])
            }
          rescue => e
            puts "\nENSURE OLD:\n#{o}"
            puts "\nNEW:\n#{n}"
            raise e
          end
        }

      end

      def find_relations(resource_uri, actual_resource_data, type)
        out = {
          sections: {},
          relations: []
        }

        puts "- properties to find size[#{actual_resource_data.size}]"

        time = Benchmark.realtime {
          out[:relations] = actual_resource_data.map! { |resource_data|
            section_group = resource_data[:section].scan(SCAN_REGEXP[:group])

            type_key = resource_data[:section].force_encoding('utf-8')

            out[:sections][type_key] ||= {
              type: section_group[0][0],
              from: section_group[0][1].to_i,
              to: section_group[0][2].to_i,
            }

            result = get_properties_by_link(resource_uri, resource_data[:link], type)

            resource_data[:properties] = result[:properties]
            resource_data[:strict_properties] = result[:strict_properties]

            resource_data
          }.compact || []
        }

        out[:time] = time.round(2)

        puts "- properties found in #{out[:time]}"

        out
      end

      def get_properties_by_link(resource_uri, link, type)
        properties = {type => {}}
        strict_properties = {type => {}}

        @query.get_all_predicates_by_subject_object(resource_uri, link).each { |solution|
          predicate = solution.to_h
          property = predicate[:property].to_s.force_encoding('utf-8')

          next if unimportant?(property)

          count = @query.get_count_predicate_by_entity(type, property)[0].to_h[:count].to_f
          strict_properties[type][property] = count if count > 0
        }

        @query.get_all_predicates_by_object(link).each { |solution|
          predicate = solution.to_h
          property = predicate[:property].to_s.force_encoding('utf-8')

          next if unimportant?(property) || strict_properties[type][property]

          count = @query.get_count_predicate_by_entity(type, property)[0].to_h[:count].to_f
          properties[type][property] = count if count > 0
        }


        {properties: properties, strict_properties: strict_properties}
      end

      def generate_result_file(resource_uri, type, result_relations, this_time)
        section_degradation = result_relations[:sections].map { |section_type, position|
          index = result_relations[:sections].keys.index(section_type)

          # recognize value of degradation by relative position paragraphs in document
          position[:degradation] = 1 - ((index / result_relations[:sections].size) / 10.0)

          {section_type => position}
        }.reduce(:merge)

        total_size = section_degradation.max_by { |_, v| v[:to] }[1][:to].to_f

        result_nif_data = result_relations[:relations].map { |relation|
          paragraph_position = section_degradation[relation[:section]]

          # weight is lowest by relative distance from document start
          position_weight = (1 - ((relation[:indexes][0].to_i) / total_size))
          # weight is also degraded by index of paragraph
          relation[:weight] = (position_weight * paragraph_position[:degradation]).round(4)

          relation
        }

        result = {
          process_time: {nif_find: this_time, relations_find: result_relations[:time]},
          resource_uri: resource_uri,
          nif_data: result_nif_data
        }

        result_path = get_resource_file_path(resource_uri, type)
        File.open(result_path, 'w:utf-8') { |f| f << JSON.pretty_generate(result) }
      end


      def generate_knowledge_base(type, best_count = 20, identify_identical = true)
        puts "_____ #{type} _____"
        files = Dir.glob("#{@results_dir_path}/#{type}/*.json")
        type = type.to_s.to_sym

        knowledge_data = {type => []}

        files.each { |file_path|
          puts "- calculate #{file_path}"
          file_data = JSON.parse(File.read(file_path).force_encoding('utf-8'), symbolize_names: true)


          if identify_identical
            file_data[:nif_data].each { |data|
              identify_identical_predicates(data[:properties][type].keys)
            }
            store_identical_properties
          end

          file_data[:nif_data].each { |found|
            properties = found[:properties][type.to_sym]
            weight = found[:weight]

            properties.each { |property, count|
              property = property.to_s
              value = count.to_i * weight

              prepare_add_property_to_knowledge(type, property, knowledge_data) { |from_knowledge|
                old_score = from_knowledge[:score] * from_knowledge[:counter]
                from_knowledge[:counter] += 1
                (old_score + value) / from_knowledge[:counter]
              }
            }
          }


        }

        unless knowledge_data[type].empty?
          max_weight = knowledge_data[type].max_by { |data| data[:score] }[:score]
          knowledge_data[type] = knowledge_data[type].map { |hash|
            hash[:score] = (hash[:score] / max_weight).round(4)
            hash.delete(:counter)
            hash
          }
        end

        puts "#{__method__} - global literal properties"

        global_properties = get_global_statistic_by_type(type) || {}
        if identify_identical
          identify_identical_predicates(global_properties.keys)
          store_identical_properties
        end

        max_count = global_properties.max_by { |_, count| count }[1].to_f
        global_properties.each { |property, count|
          value = count / max_count
          prepare_add_property_to_knowledge(type, property, knowledge_data, false) { |from_knowledge|
            from_knowledge[:score] > 0 ? (from_knowledge[:score] + value / 2.0).round(4) : value.round(4)
          }
        }

        knowledge_data[type] = knowledge_data[type].sort_by { |hash| hash[:score] }.reverse.take(best_count)

        update_knowledge_base(knowledge_data)
      end

      def identify_identical_predicates(properties, identical_limit = IDENTICAL_PROPERTY_LIMIT)
        @temp_counts ||= {}

        load_identical_predicates

        combinations = properties.combination(2).to_a

        combinations.each { |values|
          values = values.map { |p| p.to_s }.sort

          group_key = "#{values[0]}_#{values[1]}".to_sym

          already_mark_same = @identical_predicates.find(group_key)
          already_mark_different = @different_predicates.find(group_key)

          if already_mark_same.nil? && already_mark_different.nil?

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
              puts "     - result[#{identical_level}] z[#{z}] x[#{x}] y[#{y}] #{values.inspect}"
              @identical_predicates << group_key
            else
              @different_predicates << group_key
            end
          end
        }

      end

      def generate_literal_statistics(entities_type = nil, count = 10)
        unless entities_type
          entities_type = get_all_classes
        end

        entities_type = [entities_type] unless entities_type.is_a?(Array)

        entities_type.each_with_index { |entity_type, index|
          all_properties = {}
          puts "#{__method__} - start process entity type: #{entity_type} [#{(index / entities_type.size.to_f).round(2)}]"
          entity_type = entity_type.to_s.to_sym

          get_best_ranked_resources(entity_type, count).each { |resource, _|
            properties = @query.get_all_predicates_by_subject(resource.to_s, true).map { |solution_prop|
              solution_prop[:property].to_s
            } || []

            properties.uniq.each { |prop|
              next if unimportant?(prop)
              all_properties[entity_type] ||= {}
              all_properties[entity_type][prop] ||= 0
              all_properties[entity_type][prop] += 1
            }

          }

          update_global_statistic(all_properties)
        }
      end

      def get_all_classes(path = '../knowledge/classes_hierarchy.json')
        data = ensure_load_json(path, {})
        HashHelper.recursive_map_keys(data)
      end


      private

      def prepare_add_property_to_knowledge(type, property, knowledge_data, counter = true)
        load_identical_predicates(true) unless @identical_predicates

        found = knowledge_data[type].find { |data| data[:predicates].include?(property.to_s) }

        unless found
          # add new

          found = {
            score: 0.0,
            predicates: @identical_predicates.find { |group| group.include?(property.to_s) } || [property.to_s]
          }
          found[:counter] = 0 if counter

          knowledge_data[type] ||= []
          knowledge_data[type] << found
        end

        new_score = yield found

        found[:score] = new_score
      end

      ###
      # The method helps identify unimportant predicate by constants.
      #
      # @param [String] property
      #
      # @return [TrueClass, FalseClass] result
      def unimportant?(property)
        property = property.to_s
        NO_SENSE_PROPERTIES.include?(property) || COMMON_PROPERTIES.include?(property)
      end

      ###
      # The method generate file path for given resource URI.
      # Also ensure to exist sub directory by resource entity type.
      #
      # @param [String] resource_uri
      # @param [String] type
      #
      # @return [String] resource_file_path
      def get_resource_file_path(resource_uri, type)
        type = type.split('/').last
        resource_name = resource_uri.split('/').last

        dir_path = "#{@results_dir_path}/#{type}"
        Dir.mkdir(dir_path) unless Dir.exist?(dir_path)

        "#{dir_path}/#{StringHelper.get_clear_file_path(resource_name)}.json"
      end

      ###
      # The method helps update found predicates to stored links.
      #
      # @param [String] resource_uri
      # @param [String] type
      #
      # @return []
      def update_nif_file_properties(resource_uri, type)
        if block_given?
          path = get_resource_file_path(resource_uri, type)
          old_data = ensure_load_json(path, {}, symbolize_names: true)

          new_data = old_data.dup

          time = Benchmark.realtime {
            new_data[:nif_data] = old_data[:nif_data].map { |hash|
              actual_link = hash[:link].to_sym

              result = yield actual_link

              hash[:strict_properties] = result[:strict_properties] if result[:strict_properties]
              hash[:properties] = result[:properties] if result[:properties]

              hash
            }
          }

          new_data[:process_time][:relations_find] = time.round(2)

          File.write(path, JSON.pretty_generate(new_data))
          return old_data, new_data
        end
      end

      def keep_unloaded(resources)
        resources.delete_if { |resource, values|
          dir_path = "#{@results_dir_path}/#{values[:type]}"
          resource_name = resource.split('/').last
          File.exists?("#{dir_path}/#{StringHelper.get_clear_file_path(resource_name)}.json")
        }
      end

      def keep_loaded(resources)
        resources.keep_if { |resource, values|
          dir_path = "#{@results_dir_path}/#{values[:type]}"
          resource_name = resource.split('/').last
          File.exists?("#{dir_path}/#{StringHelper.get_clear_file_path(resource_name)}.json")
        }
      end

      def update_knowledge_base(new_data)
        path = "#{@results_dir_path}/knowledge_base.json"
        old_data = ensure_load_json(path, {}, symbolize_names: true)
        File.write(path, JSON.pretty_generate(old_data.merge(new_data)))
      end

      def update_global_statistic(new_data)
        path = "#{@results_dir_path}/global_statistic.json"
        old_data = ensure_load_json(path, {}, symbolize_names: true)
        File.write(path, JSON.pretty_generate(old_data.merge(new_data)))
      end

      def get_global_statistic_by_type(type)
        type = type.to_s.to_sym
        path = "#{@results_dir_path}/global_statistic.json"
        data = ensure_load_json(path, {}, symbolize_names: true)
        data[type]
      end

      def store_identical_properties(identical = true, different = true)
        File.write("#{@results_dir_path}/identical_predicates.json", JSON.pretty_generate(@identical_predicates)) if identical
        File.write("#{@results_dir_path}/different_predicates.json", JSON.generate(@different_predicates)) if different
      end

      def load_identical_predicates(no_different = false)
        unless @identical_predicates
          file_path = "#{@results_dir_path}/identical_predicates.json"
          @identical_predicates = ensure_load_json(file_path, [])
        end

        unless no_different
          unless @different_predicates
            file_path = "#{@results_dir_path}/different_predicates.json"
            @different_predicates = ensure_load_json(file_path, [])
          end
        end
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

      def parse_group_to_resource_uri(lines_group)
        (lines_group[0].scan(SCAN_REGEXP[:scan_resource])[0])[0].split('?').first
      end

      def parse_line_group(lines_group)
        begin_index = lines_group[2].scan(SCAN_REGEXP[:begin_index])[0]
        end_index = lines_group[3].scan(SCAN_REGEXP[:end_index])[0]
        target_resource_link = lines_group[5].scan(SCAN_REGEXP[:target_resource_link])[0]
        section = lines_group[4].scan(SCAN_REGEXP[:section])[0]
        anchor = lines_group[6].scan(SCAN_REGEXP[:anchor])[0]

        {
          link: target_resource_link[1].force_encoding('utf-8'),
          anchor: anchor[1].force_encoding('utf-8'),
          indexes: [begin_index[1], end_index[1]],
          section: section[0].split('=')[1]
        }
      end
    end
  end

end