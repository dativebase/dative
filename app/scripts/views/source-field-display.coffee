define [
  './related-resource-field-display'
  './source'
  './../models/source'
  './../collections/sources'
], (RelatedResourceFieldDisplayView, SourceView, SourceModel,
  SourcesCollection) ->

  # Related Source Field Display View
  # ----------------------------------
  #
  # For displaying a source as a field/attribute of another resource, such that
  # the source is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class SourceFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'source'
    attributeName: 'source'
    resourceModelClass: SourceModel
    resourcesCollectionClass: SourcesCollection
    resourceViewClass: SourceView

    resourceAsString: (resource) ->
      tmp = new @resourceModelClass resource
      try
        "#{tmp.getAuthor()} (#{tmp.getYear()})"
      catch
        ''

