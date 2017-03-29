# encoding: utf-8

module SPARQLQueries

  def resources_by_dbpedia_page_rank(entity_type, limit = 10)
    entity_type = entity_type['http'] ? "<#{entity_type}>" : "dbo:#{entity_type}"

    " PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX dbo:<http://dbpedia.org/ontology/>
      PREFIX vrank:<http://purl.org/voc/vrank#>

      SELECT ?entity ?rank
      FROM <http://dbpedia.org>
      FROM <http://people.aifb.kit.edu/ath/#DBpedia_PageRank>
      WHERE {
        ?entity rdf:type #{entity_type}.
        ?entity vrank:hasRank/vrank:rankValue ?rank.
      }
      ORDER BY DESC(?rank) LIMIT #{limit}"
  end

  def all_predicates_by_object(object)
    object = object['http'] ? "<#{object}>" : "dbo:#{object}"

    " PREFIX dbo:	<http://dbpedia.org/ontology/>
      PREFIX dbp:	<http://dbpedia.org/property/>

      SELECT DISTINCT ?property

      WHERE {
        ?subject ?property #{object}.
      }"
  end

  def all_predicates_by_subject(subject, only_literal)
    subject = subject['http'] ? "<#{subject}>" : "dbo:#{subject}"
    filter = only_literal ? 'FILTER(isLiteral(?object))' : nil

    " PREFIX dbo:	<http://dbpedia.org/ontology/>
      PREFIX dbp:	<http://dbpedia.org/property/>

      SELECT DISTINCT ?property

      WHERE {
        #{subject} ?property ?object.
        #{filter}
      }"
  end

  def count_predicate_by_entity(entity_class, predicate)
    entity_class = entity_class['http'] ? "<#{entity_class}>" : "dbo:#{entity_class}"
    predicate = predicate['http'] ? "<#{predicate}>" : "dbo:#{predicate}"

    " PREFIX dbo:	<http://dbpedia.org/ontology/>
      PREFIX dbp:	<http://dbpedia.org/property/>

      SELECT DISTINCT COUNT(?subject) as ?count

      WHERE {
        ?subject a #{entity_class} .
        {?subject #{predicate} ?a .} UNION {?b #{predicate} ?subject .}
      }

      ORDER BY DESC(?count)"
  end

  def count_of_identical_predicates(predicates)
    predicates = [predicates] unless predicates.is_a?(Array)
    where_part = predicates.map{|predicate|
      predicate = predicate['http'] ? "<#{predicate}>" : "dbo:#{predicate}"
      "?subject #{predicate} ?object ."
    }.join("\n")

    " SELECT COUNT(DISTINCT ?subject) AS ?count
      WHERE{#{where_part}
     }"
  end

  def resource_properties(resource, lang = 'en')
    resource = resource['http'] ? "<#{resource}>" : "<http://dbpedia.org/resource/#{resource}>"

    " PREFIX dbo:	<http://dbpedia.org/ontology/>
      PREFIX dbp:	<http://dbpedia.org/property/>
      SELECT DISTINCT ?predicate, ?predicate_label, ?value, ?value_label
      WHERE {
        { #{resource} ?predicate ?value . } UNION { ?value ?predicate #{resource} . }

        OPTIONAL{
          ?value rdfs:label ?value_label .
          FILTER (lang(?value_label) = '#{lang}')
        }

        ?predicate rdfs:label ?predicate_label .
        FILTER (lang(?predicate_label) = '#{lang}')
      }"
  end

  def entity_classes(resource)
    resource = resource['http'] ? "<#{resource}>" : "<http://dbpedia.org/resource/#{resource}"

    " SELECT DISTINCT ?entity_class
      WHERE {
        #{resource} a ?entity_class .
        ?entity_class a owl:Class .
      }"
  end

  def self.included(base)
    base.extend SPARQLQueries
  end

end