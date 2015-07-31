define [
  './resource'
  './tag-add-widget'
  './date-field-display'
], (ResourceView, TagAddWidgetView, DateFieldDisplayView) ->

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
      datetime_modified: DateFieldDisplayView

