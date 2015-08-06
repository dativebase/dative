define [
  './related-resource-field-display'
  './tag'
  './../models/tag'
], (RelatedResourceFieldDisplayView, TagView, TagModel) ->

  # Related Tag Field Display View
  # ----------------------------------
  #
  # For displaying a tag as a field/attribute of another resource, such that
  # the tag is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class TagFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'tag'
    attributeName: 'tag'
    resourceModelClass: TagModel
    resourceViewClass: TagView

    resourceAsString: (resource) ->
      try
        resource.name
      catch
        ''

