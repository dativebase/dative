define [
  './array-of-related-resources-field-display'
  './tag'
  './../models/tag'
  './../collections/tags'
], (ArrayOfRelatedResourcesFieldDisplayView, TagView, TagModel,
  TagsCollection) ->

  # Array of Related Tags Field Display View
  # ----------------------------------------
  #
  # For displaying the tags that are related to another resource. Each tag is
  # represented by a link (whose text is the name) that triggers an opening of
  # the tag in a dialog box.

  class ArrayOfRelatedTagsFieldDisplayView extends ArrayOfRelatedResourcesFieldDisplayView

    resourceName: 'tag'
    attributeName: 'tags'

    getContext: ->
      _.extend(super,
        subattribute: 'id'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: @resourceName
        attributeName: @attributeName
        resourceModelClass: TagModel
        resourcesCollectionClass: TagsCollection
        resourceViewClass: TagView
        resourceAsString: @resourceAsString
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

    # The string returned by this method will be the text of link that
    # represents each selected tag.
    # NOTE: the repetitive logic here is for search match highlighting.
    resourceAsString: (resourceId) ->
      resource = _.findWhere(@model.get(@attributeName), {id: resourceId})
      if resource.name
        if @context.searchPatternsObject
          try
            regex = @context.searchPatternsObject[@attributeName].name
          catch
            regex = null
          if regex
            @utils.highlightSearchMatch regex, resource.name
          else
            resource.name
        else
          resource.name
      else
        "Tag #{resource.id}"

