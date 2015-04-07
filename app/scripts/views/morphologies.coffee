define [
  './resources'
  './morphology'
  './../collections/morphologies'
  './../models/morphology'
], (ResourcesView, MorphologyView, MorphologiesCollection, MorphologyModel) ->

  # Morphologies View
  # -----------------
  #
  # Displays a collection of morphologies for browsing, with pagination. Also
  # contains a model-less MorphologyView instance for creating new morphologies
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class MorphologiesView extends ResourcesView

    resourceName: 'morphology'
    resourceView: MorphologyView
    resourcesCollection: MorphologiesCollection
    resourceModel: MorphologyModel

