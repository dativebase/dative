define [
  './resources'
  './orthography'
  './../collections/orthographies'
  './../models/orthography'
  './../utils/globals'
], (ResourcesView, OrthographyView, OrthographiesCollection,
  OrthographyModel, globals) ->

  # Orthographies View
  # ------------------
  #
  # Displays a collection of orthographies for browsing, with pagination. Also contains
  # a model-less `OrthographyView` instance for creating new orthographies within
  # the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class OrthographiesView extends ResourcesView

    resourceName: 'orthography'
    resourceView: OrthographyView
    resourcesCollection: OrthographiesCollection
    resourceModel: OrthographyModel


