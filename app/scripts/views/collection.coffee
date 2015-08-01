define [
  './resource'
  './collection-add-widget'
  './date-field-display'
  './related-user-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './source-field-display'
  './html-snippet-display'
  './person-field-display'
  './array-of-objects-with-name-field-display'
], (ResourceView, CollectionAddWidgetView, DateFieldDisplayView,
  RelatedUserFieldDisplayView, EntererFieldDisplayView,
  ModifierFieldDisplayView, SourceFieldDisplayView,
  HTMLSnippetFieldDisplayView, PersonFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView) ->


  class ElicitorFieldDisplayView extends RelatedUserFieldDisplayView

    attributeName: 'elicitor'


  # Collection View
  # ---------------
  #
  # For displaying individual collections (i.e., OLD text-like resources).

  class CollectionView extends ResourceView

    resourceName: 'collection'

    resourceAddWidgetView: CollectionAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'title'
      'description'
      'type'
      'url'
      'markup_language'
      'html'
      'source' #
      'speaker' #
      'elicitor' #
      'date_elicited' #
      'tags' #
      'files' #
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'enterer' #
      'modifier' #
      'datetime_entered' #
      'datetime_modified' #
      'UUID'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      date_elicited: DateFieldDisplayView
      speaker: PersonFieldDisplayView
      elicitor: ElicitorFieldDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      source: SourceFieldDisplayView
      tags: ArrayOfObjectsWithNameFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView
      html: HTMLSnippetFieldDisplayView


