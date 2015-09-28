define [
  './resources'
  './../models/tag'
], (ResourcesCollection, TagModel) ->

  # Tags Collection
  # ---------------
  #
  # Holds models for tags.

  class TagsCollection extends ResourcesCollection

    resourceName: 'tag'
    model: TagModel



