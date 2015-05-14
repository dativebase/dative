define [
  './resources'
  './../models/morphological-parser'
], (ResourcesCollection, MorphologicalParserModel) ->

  # Morphological Parsers Collection
  # --------------------------------
  #
  # Holds models for morphological parsers.

  class MorphologicalParsersCollection extends ResourcesCollection

    resourceName: 'morphologicalParser'
    model: MorphologicalParserModel

    serverSideResourceName: 'morphologicalparsers'

