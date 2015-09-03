define [
  './resource'
  './subcorpus-controls'
  './subcorpus-add-widget'
  './search'
  './field-display'
  './related-resource-field-display'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './array-of-related-tags-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './../models/search'
  './../collections/searches'
], (ResourceView, SubcorpusControlsView, SubcorpusAddWidgetView, SearchView,
  FieldDisplayView, RelatedResourceFieldDisplayView,
  PersonFieldDisplayView, DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView,
  ArrayOfRelatedTagsFieldDisplayView, EntererFieldDisplayView,
  ModifierFieldDisplayView, SearchModel, SearchesCollection) ->

  class FormSearchDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'search'
    attributeName: 'form_search'
    resourceModelClass: SearchModel
    resourcesCollectionClass: SearchesCollection
    resourceViewClass: SearchView


  # Subcorpus View
  # --------------
  #
  # For displaying individual subcorpora.

  class SubcorpusView extends ResourceView

    resourceName: 'subcorpus'

    resourceNameHumanReadable: => 'corpus'

    resourceAddWidgetView: SubcorpusAddWidgetView

    excludedActions: ['history', 'data']

    controlsViewClass: SubcorpusControlsView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'description'
      'content'
      'tags'
      'form_search'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'files'
      'UUID'
      'id'
    ]

    attribute2displayView:
      tags: ArrayOfRelatedTagsFieldDisplayView
      form_search: FormSearchDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

    getHeaderTitle: ->
      if @model.get('id') then "Corpus #{@model.get 'id'}" else "New Corpus"

