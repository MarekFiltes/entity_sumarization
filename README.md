# DBpedia entity sumarization
Ruby tool to entity sumarization.

## Tool description
Tool was developed as part of diploma thesis. Tool lookup resource links that is included in Wikipedia abstract.
Links are stored in dataset of NLP Interchange Format (NIF). In next step find all relations in witch are used collected links to entities of given class (eg. City, Artist, ...).   

## Basic usage

### Install

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
process_time - relative time to find links in nif dataset and time to find relations with that link.
resource_uri - resource
nif_data - contains hashes of found links, anchor for link, indexes of anchor, paragraph information and relations by entity class.
 
#### Strict predicates
  
#### Predicates

File data example: 
```json
{
  "process_time": {
    "nif_find": 2.1,
    "relations_find": 2.56
  },
  "resource_uri": "http://dbpedia.org/resource/American_Mathematical_Monthly",
  "nif_data": [
    {
      "link": "http://dbpedia.org/resource/Mathematics",
      "anchor": "mathematical",
      "indexes": [
        "39",
        "51"
      ],
      "section": "paragraph_0_175",
      "properties": {
        "AcademicJournal": {
          "http://dbpedia.org/ontology/academicDiscipline": 7849.0,
          "http://dbpedia.org/ontology/award": 28.0,
          "http://dbpedia.org/ontology/field": 46.0,
          "http://dbpedia.org/ontology/genre": 4.0,
          "http://dbpedia.org/ontology/knownFor": 80.0,
          "http://dbpedia.org/ontology/literaryGenre": 2.0,
          "http://dbpedia.org/ontology/mainInterest": 4.0,
          "http://dbpedia.org/ontology/nonFictionSubject": 2.0,
          "http://dbpedia.org/ontology/occupation": 8.0,
          "http://dbpedia.org/ontology/profession": 1.0,
          "http://dbpedia.org/ontology/type": 9.0,
          "http://dbpedia.org/property/subject": 2.0,
          "http://dbpedia.org/property/discipline": 7659.0,
          "http://dbpedia.org/property/field": 22.0,
          "http://dbpedia.org/property/fields": 13.0,
          "http://dbpedia.org/property/genre": 2.0,
          "http://dbpedia.org/property/knownFor": 30.0,
          "http://dbpedia.org/property/occupation": 2.0,
          "http://dbpedia.org/property/profession": 1.0,
          "http://dbpedia.org/property/type": 8.0
        }
      },
      "weight": 0.9593
    },
    {
      "link": "http://dbpedia.org/resource/Benjamin_Finkel",
      "anchor": "Benjamin Finkel",
      "indexes": [
        "71",
        "86"
      ],
      "section": "paragraph_0_175",
      "properties": {
        "AcademicJournal": {

        }
      },
      "weight": 0.9259
    },
    {
      "link": "http://dbpedia.org/resource/Mathematical_Association_of_America",
      "anchor": "Mathematical Association of America",
      "indexes": [
        "139",
        "174"
      ],
      "section": "paragraph_0_175",
      "properties": {
        "AcademicJournal": {
          "http://dbpedia.org/ontology/award": 28.0,
          "http://dbpedia.org/ontology/publisher": 6266.0,
          "http://dbpedia.org/property/company": 1.0,
          "http://dbpedia.org/property/publisher": 6149.0
        }
      },
      "weight": 0.8549
    },
    {
      "link": "http://dbpedia.org/resource/JSTOR",
      "anchor": "JSTOR",
      "indexes": [
        "701",
        "706"
      ],
      "section": "paragraph_176_707",
      "properties": {
        "AcademicJournal": {
          "http://dbpedia.org/ontology/employer": 3.0,
          "http://dbpedia.org/property/employer": 1.0
        }
      },
      "weight": 0.2683
    },
    {
      "link": "http://www.maa.org/pubs/monthly_toc_archives.html",
      "anchor": "Mathematical Association of America's website",
      "indexes": [
        "765",
        "810"
      ],
      "section": "paragraph_708_811",
      "properties": {
        "AcademicJournal": {

        }
      },
      "weight": 0.2015
    },
    {
      "link": "http://dbpedia.org/resource/Lester_R._Ford_Award",
      "anchor": "Lester R. Ford Awards",
      "indexes": [
        "830",
        "851"
      ],
      "section": "paragraph_812_958",
      "properties": {
        "AcademicJournal": {

        }
      },
      "weight": 0.1336
    }
  ]
}
```