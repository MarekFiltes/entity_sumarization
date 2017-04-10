# encoding: utf-8

###
# Core project module
module BrowserWebData

  class SPARQLRequest
    include SPARQLQueries

    def initialize(sparql_endpoint = 'http://dbpedia.org/sparql')
      @sparql_client = SPARQL::Client.new(sparql_endpoint)
    end

    def get_resources_by_dbpedia_page_rank(entity_type, count = 10)
      process_query(resources_by_dbpedia_page_rank(entity_type, count))
    end

    def get_all_predicates_by_object(object)
      process_query(all_predicates_by_object(object))
    end

    def get_all_predicates_by_subject(subject, only_literal = false)
      process_query(all_predicates_by_subject(subject, only_literal))
    end

    def get_all_predicates_by_subject_object(subject, object)
      process_query(all_predicates_by_object_and_subject(subject, object))
    end

    def get_count_predicate_by_entity(entity_class, predicate)
      process_query(count_predicate_by_entity(entity_class, predicate))
    end

    def get_count_of_identical_predicates(predicates)
      process_query(count_of_identical_predicates(predicates))[0].to_h[:count].to_s.to_f
    end

    def get_resource_properties(resource, lang = :en)
      process_query(resource_properties(resource, lang)).map{|solution|
        solution = solution.to_h
        {
          predicate: solution[:predicate],
          predicate_label: solution[:predicate_label],
          value: solution[:value],
          value_label: solution[:value_label]
        }
      }
    end

    def get_entity_classes(resource_uri)
      process_query(entity_classes(resource_uri))
    end


    private

    def process_query(query, retries_count = 15)
      try = 1
      begin
        @sparql_client.query(query)
      rescue => e
        if try < retries_count
          sleep(5 + (try * 2))
          try += 1
          retry
        else
          raise e
        end
      end
    end

  end

end