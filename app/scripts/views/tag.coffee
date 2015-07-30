define [
  './resource'
  './tag-add-widget'
  './date-field-display'
  './field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, TagAddWidgetView, DateFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView) ->

  # Tag View
  # --------
  #
  # For displaying individual tags.

  class TagView extends ResourceView

    resourceName: 'tag'

    resourceAddWidgetView: TagAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: []

    # Attributes that may be hidden.
    secondaryAttributes: [
      'name'
      'description'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView



