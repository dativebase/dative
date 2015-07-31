define [
  './resources'
  './source'
  './../collections/sources'
  './../models/source'
  './../utils/globals'
], (ResourcesView, SourceView, SourcesCollection,
  SourceModel, globals) ->

  # Sources View
  # ------------
  #
  # Displays a collection of sources for browsing, with pagination. Also contains
  # a model-less `SourceView` instance for creating new sources within
  # the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class SourcesView extends ResourcesView

    resourceName: 'source'
    resourceView: SourceView
    resourcesCollection: SourcesCollection
    resourceModel: SourceModel

