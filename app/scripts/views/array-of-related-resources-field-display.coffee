define [
  './field-display'
  './tag'
  './array-of-related-resources-representation-set'
  './related-resource-representation'
  './../models/tag'
], (FieldDisplayView, TagView, ArrayOfRelatedResourcesRepresentationSetView,
  RelatedResourceRepresentationView, TagModel) ->

  # Array of Related Resource Fields Display View
  # ---------------------------------------------
  #
  # A view for displaying an array of `RelatedResourceFieldDisplayView`
  # instances. That is, this is useful when you want to display all of the tags
  # associated to a form such that each tag is a ling that, when clicked, opens
  # up that resource in a dialog view in the page.

  class ArrayOfRelatedResourcesFieldDisplayView extends FieldDisplayView

    relatedResourceRepresentationViewClass: RelatedResourceRepresentationView

    getContext: ->
      _.extend(super,
        subattribute: 'name'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: 'tag'
        attributeName: 'tags'
        resourceModelClass: TagModel
        resourceViewClass: TagView
        resourceAsString: (r) -> r
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

    getRepresentationView: ->
      new ArrayOfRelatedResourcesRepresentationSetView @context

