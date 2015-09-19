define [
  './resource'
  './orthography-add-widget'
  './date-field-display'
  './field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, OrthographyAddWidgetView, DateFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView) ->

  # Orthography View
  # ----------------
  #
  # For displaying individual orthographies.

  class OrthographyView extends ResourceView

    resourceName: 'orthography'

    resourceAddWidgetView: OrthographyAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'orthography'
      'lowercase'
      'initial_glottal_stops'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView




