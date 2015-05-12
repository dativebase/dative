define [
  './resources'
  './morphological-parser'
  './../collections/morphological-parsers'
  './../models/morphological-parser'
], (ResourcesView, MorphologicalParserView, MorphologicalParsersCollection,
  MorphologicalParserModel) ->

  # Morphological Parsers View
  # --------------------------
  #
  # Displays a collection of morphological parsers for browsing, with
  # pagination. Also contains a model-less MorphologicalParserView instance for
  # creating new morphological parsers within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class MorphologicalParsersView extends ResourcesView

    resourceName: 'morphologicalParser'
    resourceView: MorphologicalParserView
    resourcesCollection: MorphologicalParsersCollection
    resourceModel: MorphologicalParserModel

