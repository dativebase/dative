define [
  './resource'
  './keyboard-add-widget'
  './date-field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, KeyboardAddWidgetView, DateFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView) ->

  # Keyboard View
  # -------------
  #
  # For displaying individual keyboards.

  class KeyboardView extends ResourceView

    resourceName: 'keyboard'

    resourceAddWidgetView: KeyboardAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
      'keyboard'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'enterer'
      'datetime_entered'
      'modifier'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView


