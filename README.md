# DBpedia entity sumarization
Ruby tool to entity sumarization. [Sumarization results](results/).

## Tool description
Tool was developed as part of diploma thesis. Tool generate .json knowledge base.
Knowledge base is based on outward resource links from Wikipedia abstracts, 
global link relations of entity classes and global literal relations of entity classes.
Strict links are collected from dataset of NLP Interchange Format (NIF). 
In next step find all relations in which are used collected links for entities of given class (eg. City, Artist, ...).
Linked based relations are expanded with entity class global relations that point to literal.
Tool can reduce basic duplicates of predicates. 
At the end calculate total score for every predicate and generate knowledge base.    

### RubyDoc
[browser_web_data_entity_sumarization-1.1.0](http://www.rubydoc.info/gems/browser_web_data_entity_sumarization/1.1.0)

---

## Basic usage
Requires installed JRuby on machine.

This project is mainly based on usage of dataset in NIF format. 
For example can be download from 
http://wiki.dbpedia.org/nif-abstract-datasets

### Install

CMD:
```cmd
gem install browser_web_data_entity_sumarization
```
### How to initialize tool in project

Gemfile:
```ruby
gem 'browser_web_data_entity_sumarization'
```

### How to initialize tool in script

Script:
```ruby
require 'browser_web_data_entity_sumarization'
```
### Use in script

#### Initialize main instance of statistic
```ruby
 nif_dataset_path = 'nif-text-links_en.ttl'
 resource_dir = 'statisticts/'
 statistic = BrowserWebData::EntitySumarization::Statistic.new(nif_dataset_path, resource_dir, true)
```

#### Start generate complete knowledge base for all entity class types
**nif_dataset is required**. Knowledge base is generate from link statistics and literal statistics
```ruby
params = {
  entity_types: statistic.get_all_classes, # [City, Person, ... ]
  entity_count: 10, # count of best ranked resource for every entity type
  demand_reload: false, # resource is skipped if already has stored in result dir
  console_output: true, # allow to display some information from process
  identify_identical_predicates: false # try to find identical predicates and grouped them as one item
}

statistic.create_complete_knowledge_base(params)
```
Warning: Parameter **identify_identical_predicates: true** can increased process time 
identification is based on verifying every combination of predicates list. 
Method reduce list to max 250 predicates. 
All resource are completed by one iteration from NIF dataset file. 

#### Start generate only global literal statistic
**nif_dataset is no required**
```ruby
entity_class_type = 'http://www.w3.org/2002/07/owl#Thing'
resources_limit = 1000

statistic.generate_literal_statistics(entity_class_type, resources_limit)
```
and alternatively for all classes:
```ruby
resources_limit = 1000

statistic.get_all_classes.each{|entity_class_type|
  statistic.generate_literal_statistics(entity_class_type, resources_limit)
}
```

#### Refresh resource statistic files
**nif_dataset is no required.**
If links has already extracted from NIF dataset 
and need only reload predicates from DBpedia, can use:
```ruby
best_ranked_resource_count = 100

statistic.refresh_statistics_in_files(statistic.get_all_classes, resources_limit)
```
_(currently is no allowed to specify which files might be refreshed, 
only by define entity classes and count of resources to find by best rank.)_

#### Recalculate knowledge base
**nif_dataset is no required.**
In case you need to recalculate predicates count and update knowledge base, 
can use:
```ruby
entity_class_type = 'http://www.w3.org/2002/07/owl#Thing'
identify_identical_predicates = false

statistic.generate_knowledge_base(entity_class_type, identify_identical_predicates)
```
Warning: Parameter **identify_identical_predicates: true** can increased process time 
identification is based on verifying every combination of predicates list. 
Method reduce list to max 250 predicates. 

and alternatively for all classes:
```ruby
identify_identical_predicates = false

statistic.get_all_classes.each{|entity_class_type|
  statistic.generate_knowledge_base(entity_class_type, identify_identical_predicates)
}
```

---

## Results description 
Results published in this project [Sumarization results](results/) 
was generated from NIF dataset: nif-text-links_en
[2016-04/ext/nif-abstracts/en/](http://downloads.dbpedia.org/2016-04/ext/nif-abstracts/en/)

Results contains:
- knowledge_base.json
- global_statistics.json
- identical_predicates.json
- statistics.zip


### Global statistic
Statistics contains predicates with their total count. 
Predicates are assign to every entity class.
This project requires only predicates that point to literals.

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
                  
#### Strict predicates/properties
Base relation:</br> 
\<resource> ?property \<link>
  
#### Predicates/properties
Base relation:</br>  
?subject a \<entity_class\><br> 
?subject ?property \<link\>

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

### Knowledge base example
Every entity class types has assign sorted array of hash 
with grouped predicates with score value. Predicates in array are marked as identical.
This can help to reduce duplicate information in summary.
```json
{
  "Game": [
    {
      "score": 0.8912,
      "predicates": [
        "http://dbpedia.org/ontology/designer",
        "http://dbpedia.org/property/designer"
      ]
    },
    {
      "score": 0.8777,
      "predicates": [
        "http://dbpedia.org/ontology/publisher",
        "http://dbpedia.org/property/publisher"
      ]
    },
    {
      "score": 0.5291,
      "predicates": [
        "http://dbpedia.org/ontology/subtitle",
        "http://dbpedia.org/property/subtitle"
      ]
    },
    {
      "score": 0.4373,
      "predicates": [
        "http://dbpedia.org/ontology/genre",
        "http://dbpedia.org/property/genre"
      ]
    },
    {
      "score": 0.4237,
      "predicates": [
        "http://dbpedia.org/ontology/illustrator",
        "http://dbpedia.org/property/illustrator"
      ]
    },
    {
      "score": 0.1968,
      "predicates": [
        "http://dbpedia.org/property/date"
      ]
    },
    {
      "score": 0.1968,
      "predicates": [
        "http://dbpedia.org/ontology/publicationDate"
      ]
    },
    {
      "score": 0.1142,
      "predicates": [
        "http://dbpedia.org/ontology/product"
      ]
    },
    {
      "score": 0.0552,
      "predicates": [
        "http://dbpedia.org/property/products"
      ]
    },
    {
      "score": 0.0259,
      "predicates": [
        "http://dbpedia.org/ontology/series",
        "http://dbpedia.org/property/series"
      ]
    },
    {
      "score": 0.0228,
      "predicates": [
        "http://dbpedia.org/ontology/manufacturer",
        "http://dbpedia.org/property/manufacturer"
      ]
    },
    {
      "score": 0.0208,
      "predicates": [
        "http://dbpedia.org/property/shortDescription",
        "http://purl.org/dc/elements/1.1/description"
      ]
    },
    {
      "score": 0.016,
      "predicates": [
        "http://dbpedia.org/property/released"
      ]
    },
    {
      "score": 0.0148,
      "predicates": [
        "http://dbpedia.org/ontology/recordLabel",
        "http://dbpedia.org/property/label"
      ]
    },
    {
      "score": 0.0125,
      "predicates": [
        "http://dbpedia.org/ontology/mediaType",
        "http://dbpedia.org/property/mediaType"
      ]
    }
   ]
}
```

## Example of results usage
http://browserwebdata.herokuapp.com

## License
MIT License, Copyright (c) 2017 GitHub Inc.

[License details](LICENSE.md)
