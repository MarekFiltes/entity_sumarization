# encoding: utf-8

module BrowserWebData

  TMP_DIR = 'BROWSER_WEB_DATA'

  module EntitySumarizationConfig

    IDENTICAL_PROPERTY_LIMIT = 0.8

    NO_SENSE_PROPERTIES = %w(
http://xmlns.com/foaf/0.1/primaryTopic
http://dbpedia.org/ontology/wikiPageRedirects
http://dbpedia.org/ontology/wikiPageDisambiguates
http://dbpedia.org/ontology/wikiPageRevisionID
http://dbpedia.org/ontology/wikiPageID
http://www.w3.org/2002/07/owl#sameAs
http://www.w3.org/2000/01/rdf-schema#seeAlso
http://www.w3.org/2002/07/owl#differentFrom
http://dbpedia.org/ontology/wikiPageExternalLink
http://xmlns.com/foaf/0.1/depiction
)

    COMMON_PROPERTIES = %W(
http://dbpedia.org/ontology/thumbnail
http://xmlns.com/foaf/0.1/name
http://www.w3.org/2000/01/rdf-schema#label
http://dbpedia.org/property/name
http://dbpedia.org/property/commonName
http://dbpedia.org/property/title
http://www.w3.org/2000/01/rdf-schema#comment
http://dbpedia.org/ontology/abstract
)

    SCAN_REGEXP = {
      begin_index: /(beginIndex).*"(\d+)"/,
      end_index: /(endIndex).*"(\d+)"/,
      scan_resource: /<(http:\/\/dbpedia.org\/resource\/(.*))>/,
      target_resource_link: /(taIdentRef).*<(.*)>/,
      anchor: /(anchorOf).*"(.*)"/,
      section: / .*(nif=.*\d)/,
      group: /(\w+)_(\d+)_(\d+)/
    }

  end

end