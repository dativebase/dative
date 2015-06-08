define [
  './resource'
  './subcorpus-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
], (ResourceView, SubcorpusAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView) ->

  # Subcorpus View
  # --------------
  #
  # For displaying individual subcorpora.

  class SubcorpusView extends ResourceView

    resourceName: 'subcorpus'

    resourceNameHumanReadable: => 'corpus'

    resourceAddWidgetView: SubcorpusAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'name'
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
      tags: ArrayOfObjectsWithNameFieldDisplayView
      form_search: ObjectWithNameFieldDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

