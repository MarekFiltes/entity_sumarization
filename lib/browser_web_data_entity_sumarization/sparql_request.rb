# encoding: utf-8

###
# Core project module
module BrowserWebData

  ###
  # SPARQLRequest class helps to retrieve results from SPARQL endpoints.
  # Actual implementation is mostly suitable for http://dbpedia.org/sparql.
  class SPARQLRequest
    include SPARQLQueries

    ###
    # Create new instance of SPARQLRequest.
    #
    # @param [String] sparql_endpoint Optional parameter. Default value is http://dbpedia.org/sparql
    def initialize(sparql_endpoint = 'http://dbpedia.org/sparql')
      @sparql_client = SPARQL::Client.new(sparql_endpoint)
    end

    ###
    # The method apply request for SPARQLQueries#resources_by_dbpedia_page_rank query.
    #
    # @param [String] entity_type Type from http://mappings.dbpedia.org/server/ontology/classes/
    # @param [Fixnum] count Optional value. Default value is 10.
    #
    # @return [Array<RDF::Query::Solution>] resources
    def get_resources_by_dbpedia_page_rank(entity_type, count = 10)
      process_query(resources_by_dbpedia_page_rank(entity_type, count))
    end

    ###
    # The method apply request for SPARQLQueries#all_predicates_by_object query.
    #
    # @param [String] object Object URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Array<RDF::Query::Solution>] predicates
    def get_all_predicates_by_object(object)
      process_query(all_predicates_by_object(object))
    end

    ###
    # The method apply request for SPARQLQueries#all_predicates_by_subject query.
    #
    # @param [String] subject Subject URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Array<RDF::Solution>] resources
    # @param [TrueClass, FalseClass] only_literal
    #
    # @return [Array<RDF::Query::Solution>] predicates
    def get_all_predicates_by_subject(subject, only_literal = false)
      process_query(all_predicates_by_subject(subject, only_literal))
    end

    ###
    # The method apply request for SPARQLQueries#all_predicates_by_object query.
    #
    # @param [String] subject Subject URL. If no contain HTTP will be used prefix dbo:
    # @param [String] object Object URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Array<RDF::Query::Solution>] predicates
    def get_all_predicates_by_subject_object(subject, object)
      process_query(all_predicates_by_object_and_subject(subject, object))
    end

    ###
    # The method apply request for SPARQLQueries#count_predicate_by_entity query.
    #
    # @param [String] entity_type Type from http://mappings.dbpedia.org/server/ontology/classes/
    # @param [String] predicate Predicate URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Array<RDF::Query::Solution>] predicates
    def get_count_predicate_by_entity(entity_type, predicate)
      process_query(count_predicate_by_entity(entity_type, predicate))
    end

    ###
    # The method apply request for SPARQLQueries#count_of_identical_predicates query.
    #
    # @param [Array<String>] predicates Array of predicates URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Float] count
    def get_count_of_identical_predicates(predicates)
      process_query(count_of_identical_predicates(predicates))[0].to_h[:count].to_s.to_f
    end

    ###
    # The method apply request for SPARQLQueries#resource_properties query.
    #
    # @param [String] resource Resource URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Array<Hash>] resources_properties
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

    ###
    # The method apply request for SPARQLQueries#entity_classes query.
    #
    # @param [String] resource Resource URL. If no contain HTTP will be used prefix dbo:
    #
    # @return [Array<RDF::Query::Solution>] classes
    def get_entity_classes(resource)
      process_query(entity_classes(resource))
    end


    private

    ###
    # The method helps to process SPARQL query request to endpoint.
    #
    # @param [String] query
    # @param [Fixnum] retries_count
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