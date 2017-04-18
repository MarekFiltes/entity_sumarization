# encoding: utf-8

###
# Core project module
module BrowserWebData

  ###
  # Project logic module
  module EntitySumarization

    ###
    # Statistic class allow to find, collect and generate knowledge of entity sumarization.
    # Entity sumarization is based on use dataset of NLP Interchange Format (NIF).
    # For example datasets from http://wiki.dbpedia.org/nif-abstract-datasets
    # Knowledge is generate by information in DBpedia.
    class Statistic
      include BrowserWebData::EntitySumarizationConfig

      attr_reader :nif_file_path, :results_dir_path

      ###
      # Create new instance of Statistic class.
      #
      # @param [String] nif_dataset_path Optional param. Default value is nil.
      # @param [String] results_dir_path Default value is Optional param. Default value is Temp/BROWSER_WEB_DATA/results.
      # @param [TrueClass, FalseClass] console_output Allow puts info to console. Default is false.
      def initialize(nif_dataset_path = nil, results_dir_path = nil, console_output = false)
        nif_dataset_path = nif_dataset_path.gsub('\\', '/') if nif_dataset_path
        results_dir_path = results_dir_path.gsub('\\', '/').chomp('/') if results_dir_path

        unless Dir.exists?(results_dir_path)
          cache_dir_path = "#{Dir.tmpdir}/#{BrowserWebData::TMP_DIR}"
          Dir.mkdir(cache_dir_path) unless Dir.exist?(cache_dir_path)
          results_dir_path = "#{cache_dir_path}/results"
          Dir.mkdir(results_dir_path) unless Dir.exist?(results_dir_path)
        end

        @nif_file_path = nif_dataset_path
        @results_dir_path = results_dir_path
        @console_output = console_output

        @query = SPARQLRequest.new
        @predicates_similarity = PredicatesSimilarity.new(@results_dir_path, IDENTICAL_PROPERTY_LIMIT, console_output)
      end

      ###
      # The method find resource links in given nif file dataset.
      #
      # @param [Hash] params
      # @option params [Array<String>, String] :entity_types Types from http://mappings.dbpedia.org/server/ontology/classes/
      # @option params [Fixnum] :entity_count Best ranked resources by every entity type.
      # @option params [FalseClass, TruesClass] :demand_reload
      # @option params [FalseClass, TruesClass] :identify_identical_predicates
      def create_complete_knowledge_base(params)
        params[:entity_types] = [params[:entity_types]] unless params[:entity_types].is_a?(Array)

        generate_statistics_from_nif(params[:entity_types], params[:entity_count], params[:demand_reload])

        params[:entity_types].each { |type|
          generate_literal_statistics(type)
        }

        params[:entity_types].each { |type|
          generate_knowledge_base_for_entity(type, params[:identify_identical_predicates])
        }
      end

      ###
      # The method find links in given nif dataset. After find collect relations #find_relations.
      # For each resource generate file in @results_dir_path.
      #
      # @param [Array<String>, String] entity_types Types from http://mappings.dbpedia.org/server/ontology/classes/
      # @param [Fixnum] count Count of best ranked resources
      # @param [FalseClass, TruesClass] demand_reload
      def generate_statistics_from_nif(entity_types, count = 10, demand_reload = false)
        unless @nif_file_path
          raise RuntimeError.new('Instance has no defined return nif_dataset_path. Can not start generate from nif datset. Please create new instance.')
        end

        resources = get_best_ranked_resources(entity_types, count)
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
              this_resource_uri = NIFLineParser.parse_resource_uri(lines_group[0])

              if resources.keys.include?(this_resource_uri)
                # process group, is requested
                resource_uri = this_resource_uri
                actual_resource_data << NIFLineParser.parse_line_group(lines_group)

              elsif !actual_resource_data.empty?
                # resource changed, process actual_resource_data
                resource_hash = resources.delete(resource_uri)
                type = resource_hash[:type]

                this_time = (Time.now - time_start).round(2)
                puts "\n#{resource_uri}\n- nif found in #{this_time}\n- resources to find #{resources.size}" if @console_output

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

      ###
      # The method generate simple statistics that contain all predicates that links to literal.
      # Predicates are grouped by entity class type and also contains count of total occurrence.
      # Predicates find from best ranked resources.
      #
      # @param [String] type Type from http://mappings.dbpedia.org/server/ontology/classes/
      # @param [Fixnum] count Count of best ranked resources
      def generate_literal_statistics(type = nil, count = 10000)
        unless type
          type = get_all_classes
        end

        type = [type] unless type.is_a?(Array)

        type.each_with_index { |entity_type, index|
          all_properties = {}
          puts "#{__method__} - start process entity type: #{entity_type} [#{(index / type.size.to_f).round(2)}]" if @console_output
          entity_type = entity_type.to_s.to_sym

          get_best_ranked_resources(entity_type, count).each { |resource, _|
            properties = @query.get_all_predicates_by_subject(resource.to_s, true).map { |solution_prop|
              solution_prop[:property].to_s
            } || []

            properties.uniq.each { |prop|
              next if Predicate.unimportant?(prop)
              all_properties[entity_type] ||= {}
              all_properties[entity_type][prop] ||= 0
              all_properties[entity_type][prop] += 1
            }

          }

          update_global_statistic(all_properties)
        }
      end

      ###
      # The method return list of best ranked resources by required entity types.
      #
      # @param [Array<String>, String] entity_types Types from http://mappings.dbpedia.org/server/ontology/classes/
      # @param [Fixnum] count Count of best ranked resources
      #
      # @return [Hash] resources
      def get_best_ranked_resources(entity_types, count = 10)
        resources = {}
        entity_types = [entity_types] unless entity_types.is_a?(Array)

        entity_types.each { |type|
          top_ranked_entities = @query.get_resources_by_dbpedia_page_rank(type, count)

          top_ranked_entities.each { |solution|
            resources[solution.entity.value] = {type: type, rank: solution.rank.value.to_f}
          }
        }

        resources
      end

      ###
      # The method helps to recollect relations by already generated result files.
      #
      # @param [Array<String>, String] entity_types Types from http://mappings.dbpedia.org/server/ontology/classes/
      # @param [Fixnum] count Count of best ranked resources
      def refresh_statistics_in_files(entity_types, count = 10)
        resources = get_best_ranked_resources(entity_types, count)

        resources = keep_loaded(resources)

        resources.each { |resource_uri, resource_info|
          puts "_____ #{resource_uri} _____" if @console_output

          update_nif_file_properties(resource_uri, resource_info[:type]) { |link|
            get_predicates_by_link(resource_uri, link, resource_info[:type])
          }
        }

      end

      ###
      # The method find predicates by given link.
      # Find strict predicates that are in relation: <resource> ?predicate <link> .
      # Find predicates that are in relation: ?subject a <type> . ?subject ?predicate <link>
      #
      # @param [String] resource_uri Resource for which will be find strict properties
      # @param [String] link Link that has some importance to resource or entity type.
      # @param [String] type Type from http://mappings.dbpedia.org/server/ontology/classes/
      #
      # @return [Hash] result
      def get_predicates_by_link(resource_uri, link, type)
        properties = {type => {}}
        strict_properties = {type => {}}

        @query.get_all_predicates_by_subject_object(resource_uri, link).each { |solution|
          predicate = solution.to_h
          property = predicate[:property].to_s.force_encoding('utf-8')

          next if Predicate.unimportant?(property)

          count = @query.get_count_predicate_by_entity(type, property)[0].to_h[:count].to_f
          strict_properties[type][property] = count if count > 0
        }

        @query.get_all_predicates_by_object(link).each { |solution|
          predicate = solution.to_h
          property = predicate[:property].to_s.force_encoding('utf-8')

          next if Predicate.unimportant?(property) || strict_properties[type][property]

          count = @query.get_count_predicate_by_entity(type, property)[0].to_h[:count].to_f
          properties[type][property] = count if count > 0
        }


        {properties: properties, strict_properties: strict_properties}
      end

      ###
      # The method helps to store founded information from nif for given resource.
      #
      # @param [String] resource_uri
      # @param [String] type Type from http://mappings.dbpedia.org/server/ontology/classes/
      # @param [Hsah] result_relations Hash generated by method #find_relations
      # @option result_relations [Hash] :sections Contains key 'section_type' value 'position'
      # @option result_relations [Array<Hash>] :relations Hashes generated by method #get_predicates_by_link
      #
      # @param [Float] this_time Relative time of find in nif dataset.
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

      ###
      # The method process all generated result files from nif dataset (by entity class type)
      # to one result knowledge base file.
      #
      # @param [String] type Type from http://mappings.dbpedia.org/server/ontology/classes/
      # @param [TrueClass, FalseClass] identify_identical Flag for process identify and group identical properties as one item.
      def generate_knowledge_base_for_entity(type, identify_identical = true)
        puts "_____ #{type} _____" if @console_output
        files = Dir.glob("#{@results_dir_path}/#{type}/*.json")
        type = type.to_s.to_sym

        knowledge_data = {type => []}

        global_properties = get_global_statistic_by_type(type) || {}

        if identify_identical
          try_this_identical = {}

          files.each { |file_path|
            file_data = JSON.parse(File.read(file_path).force_encoding('utf-8'), symbolize_names: true)
            file_data[:nif_data].each { |data|
              try_this_identical.merge!(data[:properties][type]) { |_, x, y| x + y }
            }
          }

          try_this_identical.merge!(global_properties) { |_, x, y| x + y }

          if try_this_identical.size > 0
            try_this_identical = Hash[try_this_identical.sort_by { |_, v| v }.reverse]
            puts "- prepare to identify identical: total count #{try_this_identical.size}" if @console_output
            @predicates_similarity.identify_identical_predicates(try_this_identical.keys)
          end
        end

        puts "- calculate: files count #{files.size}" if @console_output
        files.each { |file_path|
          file_data = JSON.parse(File.read(file_path).force_encoding('utf-8'), symbolize_names: true)

          file_data[:nif_data].each { |found|

            properties = found[:properties][type.to_sym]
            strict_properties = (found[:strict_properties] ||{})[type] || {}
            weight = found[:weight]

            strict_properties.each { |property, count|
              property = property.to_s
              value = count.to_i * weight

              prepare_property_to_knowledge(property, knowledge_data[type]) { |from_knowledge|
                old_score = from_knowledge[:score] * from_knowledge[:counter]
                from_knowledge[:counter] += 1
                (old_score + value) / from_knowledge[:counter]
              }
            }

            properties.each { |property, count|
              property = property.to_s
              value = count.to_i * weight

              prepare_property_to_knowledge(property, knowledge_data[type]) { |from_knowledge|
                old_score = from_knowledge[:score] * from_knowledge[:counter]
                from_knowledge[:counter] += 1
                (old_score + value) / from_knowledge[:counter]
              }
            }
          }

          unless knowledge_data[type].empty?
            max_weight = knowledge_data[type].max_by { |data| data[:score] }[:score]
            knowledge_data[type] = knowledge_data[type].map { |hash|
              hash[:score] = (hash[:score] / max_weight).round(4)
              hash
            }
          end
        }


        if global_properties.size > 0
          max_count = global_properties.max_by { |_, count| count }[1].to_f
          global_properties.each { |property, count|

            value = count / max_count

            prepare_property_to_knowledge(property, knowledge_data[type]) { |from_knowledge|
              from_knowledge[:score] > 0 ? ((from_knowledge[:score] + value) / 2.0).round(4) : value.round(4)
            }
          }
        end

        knowledge_data[type].map! { |hash|
          hash.delete(:counter)
          hash
        }

        knowledge_data[type] = knowledge_data[type].keep_if { |hash|
          hash[:score] > 0
        }.sort_by { |hash|
          hash[:score]
        }.reverse

        if identify_identical
          @predicates_similarity.reduce_identical
        end

        update_knowledge_base(knowledge_data)
      end

      ###
      # The method load all defined entity class types by http://mappings.dbpedia.org/server/ontology/classes/
      #
      # @param [String] path
      #
      # @return [Array<String>] classes
      def get_all_classes(path = File.join(__dir__, '../knowledge/classes_hierarchy.json'))
        data = ensure_load_json(path, {})
        HashHelper.recursive_map_keys(data)
      end


      private

      ###
      # The method helps to continue of process find links in nif dataset.
      #
      # @param [String] resource_uri
      # @param [Hash] actual_resource_data Part data extracted from nif dataset for given resource_uri
      # @param [String] type Type from http://mappings.dbpedia.org/server/ontology/classes/
      #
      # @return [Hash] out
      def find_relations(resource_uri, actual_resource_data, type)
        out = {
          sections: {},
          relations: []
        }

        puts "- properties to find size[#{actual_resource_data.size}]" if @console_output

        time = Benchmark.realtime {
          out[:relations] = actual_resource_data.map! { |resource_data|
            section_group = resource_data[:section].scan(SCAN_REGEXP[:group])

            type_key = resource_data[:section].force_encoding('utf-8')

            out[:sections][type_key] ||= {
              type: section_group[0][0],
              from: section_group[0][1].to_i,
              to: section_group[0][2].to_i,
            }

            result = get_predicates_by_link(resource_uri, resource_data[:link], type)

            resource_data[:properties] = result[:properties]
            resource_data[:strict_properties] = result[:strict_properties]

            resource_data
          }.compact || []
        }

        out[:time] = time.round(2)

        puts "- properties found in #{out[:time]}" if @console_output

        out
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
      # @return [Array<Hash>] old_data, new_data
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

      ###
      # The method in yield block give founded hash for required property.
      # This hash contains counter, score and also all identical properties.
      # At the end update score that was get from yield block as return value.
      #
      # @param [String] property
      # @param [Array<Hash>] this_knowledge_data
      #
      # @yield param found
      # @yield return score
      def prepare_property_to_knowledge(property, this_knowledge_data)
        property = property.to_s

        this_knowledge_data ||= []
        found = this_knowledge_data.find { |data| data[:predicates].include?(property) }

        if found.nil? || found.empty?
          # add new

          identical_properties = @predicates_similarity.find_identical(property)

          found = {
            counter: 0,
            score: 0.0,
            predicates: identical_properties || [property.to_s]
          }

          this_knowledge_data << found
        end

        new_score = yield found


        found[:score] = new_score
      end

      ###
      # The method delete all resources that already has created result file
      #
      # @param [Hash{resource=>type}] resources
      def keep_unloaded(resources)
        resources.delete_if { |resource, values|
          dir_path = "#{@results_dir_path}/#{values[:type]}"
          resource_name = resource.split('/').last
          File.exists?("#{dir_path}/#{StringHelper.get_clear_file_path(resource_name)}.json")
        }
      end

      ###
      # The method keep all resources that already has created result file
      #
      # @param [Hash{resource=>type}] resources
      def keep_loaded(resources)
        resources.keep_if { |resource, values|
          dir_path = "#{@results_dir_path}/#{values[:type]}"
          resource_name = resource.split('/').last
          File.exists?("#{dir_path}/#{StringHelper.get_clear_file_path(resource_name)}.json")
        }
      end

      ###
      # The method allow to update knowledge base by every entity class type.
      #
      # @param [Hash] new_data
      def update_knowledge_base(new_data)
        path = "#{@results_dir_path}/knowledge_base.json"
        old_data = ensure_load_json(path, {}, symbolize_names: true)
        File.write(path, JSON.pretty_generate(old_data.merge(new_data)))
      end

      ###
      # The method allow to update global statistic by every entity class type.
      #
      # @param [Hash] new_data
      def update_global_statistic(new_data)
        path = "#{@results_dir_path}/global_statistic.json"
        old_data = ensure_load_json(path, {}, symbolize_names: true)
        File.write(path, JSON.pretty_generate(old_data.merge(new_data)))
      end

      ###
      # The method returns global properties for given entity class type.
      #
      # @param [String] type Type from http://mappings.dbpedia.org/server/ontology/classes/
      #
      # @return [Hash] global_statistic_by_type
      def get_global_statistic_by_type(type)
        type = type.to_s.to_sym
        path = "#{@results_dir_path}/global_statistic.json"
        data = ensure_load_json(path, {}, symbolize_names: true)
        data[type]
      end

      ###
      # The method helps to load json file.
      #
      # @param [String] file_path
      # @param [String] def_val If no exist file add values as default.
      # @param [Hash] json_params JSON.parse params
      #
      # @return [Object] json
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