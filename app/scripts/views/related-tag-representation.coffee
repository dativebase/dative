define [
  './related-resource-representation'
  './tag'
  './../models/tag'
], (RelatedResourceRepresentationView, TagView, TagModel) ->

  # Related Tag Representation View
  # ------------------------------------
  #
  # A view for a tag that is related to another resource. This is a link that,
  # when clicked, causes a ResourceView for the tag to be displayed in a dialog
  # box.

  class RelatedTagRepresentationView extends RelatedResourceRepresentationView

    initialize_: (@context) ->
      @resourceName = 'tag'
      @attributeName = 'tags'
      @resourceModelClass = TagModel
      @resourceViewClass = TagView
      @setContextValue()

    resourceAsString: (resource) -> resource

    getRelatedResourceId: ->
      _.findWhere(@context.model.get(@attributeName), {name: @context.originalValue}).id

