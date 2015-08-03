define [
  './resource'
  './collection-add-widget'
  './date-field-display'
  './related-user-field-display'
  './speaker-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './source-field-display'
  './html-snippet-display'
  './person-field-display'
  './array-of-objects-with-name-field-display'
], (ResourceView, CollectionAddWidgetView, DateFieldDisplayView,
  RelatedUserFieldDisplayView, SpeakerFieldDisplayView, EntererFieldDisplayView,
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

    getHeaderTitle: -> @getTruncatedTitleAndId()

    # Return a string consisting of the value of the model's `title` attribute
    # truncated to 40 chars, and the model's id. Note: this is probably not
    # general enough a method to be in this base class.
    getTruncatedTitleAndId: ->
      title = @model.get 'title'
      id = @model.get 'id'
      if title
        truncatedTitle = title[0..35]
        if truncatedTitle isnt title then title = "#{truncatedTitle}..."
      else
        title = ''
      if id then "#{title} (id #{id})" else title

    # Attributes that are always displayed.
    primaryAttributes: [
      'title'
      'description'
      'type'
      'url'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'markup_language'
      'html'
      'source'
      'speaker'
      'elicitor'
      'date_elicited'
      'tags'
      'files'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'UUID'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      date_elicited: DateFieldDisplayView
      speaker: SpeakerFieldDisplayView
      elicitor: ElicitorFieldDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      source: SourceFieldDisplayView
      tags: ArrayOfObjectsWithNameFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView
      html: HTMLSnippetFieldDisplayView


