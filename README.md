# DBpedia entity sumarization
Ruby tool to entity sumarization.

## Tool description
Tool was developed as part of diploma thesis. Tool lookup resource links that is included in Wikipedia abstract.
Links are stored in dataset of NLP Interchange Format (NIF). In next step find all relations in witch are used collected links to entities of given class (eg. City, Artist, ...).   

## Basic usage

### Global statistics

### Link based statistics
This method require dataset in NIF format. For example download from 
http://wiki.dbpedia.org/nif-abstract-datasets

## Results description 

### Global statistics
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