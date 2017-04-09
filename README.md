# DBpedia entity sumarization
Ruby tool to entity sumarization.

## Tool description
Tool was developed as part of diploma thesis. Tool lookup resource links that is included in Wikipedia abstract.
Links are stored in dataset of NLP Interchange Format (NIF). In next step find all relations in witch are used collected links to entities of given class (eg. City, Artist, ...).   

## Basic usage

### Install

CMD:
```cmd
gem install browser_web_data_entity_sumarization
```

Gemfile:
```ruby
gem 'browser_web_data_entity_sumarization'
```

Script:
```ruby
require 'browser_web_data_entity_sumarization'
```


### Global statistics

### Link based statistics
This method requires dataset in NIF format. For example download from 
http://wiki.dbpedia.org/nif-abstract-datasets

#### Strict properties
 
#### Properties

## Results description 

### Global statistic
Statistics contains predicates with their total count. Predicates are assign to every entity class ()
Project requires only predicates that point to literals.

File data example:
```json
{
  "Entity_type_1": {
       "predicate_1": 200,
       "predicate_2": 4321
  },
  "Entity_type_2": {
      "predicate_1": 3000,
      "predicate_3": 4321
   }
}
```

### Link statistic
- process_time - relative time to find links in nif dataset and time to find relations with that link.
- resource_uri - resource
- nif_data - contains hashes of found links, anchor for link, indexes of anchor, paragraph information and relations by entity class.
  - anchor - text from abstract
  - indexes - position of anchor in paragraphs
  - section - identifier of section where anchored text is included 
  - weight - computed by relative position anchored text in abstract
  - link
  - strict_properties
    - contains properties grouped by entity class type
    - contains properties by strict relation between resource and link
    - contains also total count of occurrence in resources by entity class type 
  - properties - contains properties   
    - contains properties grouped by entity class type
    - contains properties by relation with ignore resource uri
    - contains also total count of occurrence in resources by entity class type 
                  
#### Strict predicates
properties by relation: 
\<resource> ?property \<link>
  
#### Predicates
properties by relation: 
?subject a \<entity_class>
?subject ?property \<link>

File data example: 
```json
{
  "process_time": {
    "nif_find": 3.64,
    "relations_find": 1.85
  },
  "resource_uri": "http://dbpedia.org/resource/Hamilton_(village),_New_York",
  "nif_data": [
    {
      "link": "http://dbpedia.org/resource/Administrative_divisions_of_New_York#Village",
      "anchor": "village",
      "indexes": [
        "29",
        "36"
      ],
      "section": "paragraph_0_207",
      "properties": {
        "Village": {

        }
      },
      "weight": 0.8599,
      "strict_properties": {
        "Village": {

        }
      }
    },
    {
      "link": "http://dbpedia.org/resource/Hamilton_(town),_New_York",
      "anchor": "Hamilton",
      "indexes": [
        "64",
        "72"
      ],
      "section": "paragraph_0_207",
      "properties": {
        "Village": {

        }
      },
      "weight": 0.6908,
      "strict_properties": {
        "Village": {

        }
      }
    },
    {
      "link": "http://dbpedia.org/resource/Madison_County,_New_York",
      "anchor": "Madison County, New York",
      "indexes": [
        "76",
        "100"
      ],
      "section": "paragraph_0_207",
      "properties": {
        "Village": {
          "http://dbpedia.org/property/placeOfBirth": 2643.0,
          "http://dbpedia.org/property/placeOfDeath": 555.0,
          "http://dbpedia.org/ontology/location": 3255.0,
          "http://dbpedia.org/ontology/region": 71.0,
          "http://dbpedia.org/ontology/territory": 17.0,
          "http://dbpedia.org/ontology/deathPlace": 1708.0,
          "http://dbpedia.org/ontology/birthPlace": 7463.0,
          "http://dbpedia.org/property/birthPlace": 4606.0,
          "http://dbpedia.org/property/location": 1354.0,
          "http://dbpedia.org/property/region": 19.0
        }
      },
      "weight": 0.6329,
      "strict_properties": {
        "Village": {
          "http://dbpedia.org/ontology/isPartOf": 498630.0,
          "http://dbpedia.org/property/subdivisionName": 533823.0
        }
      }
    },
    {
      "link": "http://dbpedia.org/resource/USA",
      "anchor": "USA",
      "indexes": [
        "102",
        "105"
      ],
      "section": "paragraph_0_207",
      "properties": {
        "Village": {

        }
      },
      "weight": 0.5072,
      "strict_properties": {
        "Village": {

        }
      }
    },
    {
      "link": "http://dbpedia.org/resource/Colgate_University",
      "anchor": "Colgate University",
      "indexes": [
        "129",
        "147"
      ],
      "section": "paragraph_0_207",
      "properties": {
        "Village": {
          "http://dbpedia.org/ontology/education": 4.0,
          "http://dbpedia.org/ontology/operator": 4.0,
          "http://dbpedia.org/property/education": 2.0,
          "http://dbpedia.org/property/operator": 1.0,
          "http://dbpedia.org/property/owner": 8.0,
          "http://dbpedia.org/property/youthclubs": 3.0
        }
      },
      "weight": 0.3768,
      "strict_properties": {
        "Village": {

        }
      }
    }
  ]
}
```

## Example of results usage

http://browserwebdata.herokuapp.com