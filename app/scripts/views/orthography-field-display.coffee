define [
  './related-resource-field-display'
  './orthography'
  './../models/orthography'
  './../collections/orthographies'
], (RelatedResourceFieldDisplayView, OrthographyView, OrthographyModel,
  OrthographiesCollection) ->

  # Related Orthography Field Display View
  # --------------------------------------
  #
  # For displaying a orthography as a field/attribute of another resource, such
  # that the orthography is displayed as a link that, when clicked, causes the
  # resource to be displayed in a dialog box.

  class OrthographyFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'orthography'
    attributeName: 'storage_orthography' # change this in subclasses, e.g., to 'input_orthography'
    resourceModelClass: OrthographyModel
    resourcesCollectionClass: OrthographiesCollection
    resourceViewClass: OrthographyView

    resourceAsString: (resource) ->
      try
        if resource.orthography
          (x.trim() for x in resource.orthography.split(',')).join(', ')
        else if resource.name
          resource.name
        else
          ''
      catch
        ''

    getContext: ->
      context = super
      context.valueFormatter = (v) -> v
      context

