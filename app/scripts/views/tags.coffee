define [
  './resources'
  './tag'
  './../collections/tags'
  './../models/tag'
  './../utils/globals'
], (ResourcesView, TagView, TagsCollection,
  TagModel, globals) ->

  # Tags View
  # ---------
  #
  # Displays a collection of tags for browsing, with pagination. Also contains
  # a model-less `TagView` instance for creating new tags within
  # the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class TagsView extends ResourcesView

    resourceName: 'tag'
    resourceView: TagView
    resourcesCollection: TagsCollection
    resourceModel: TagModel


