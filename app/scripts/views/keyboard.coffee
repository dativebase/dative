define [
  './resource'
  './keyboard-add-widget'
  './keyboard-field-display'
  './date-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './../utils/globals'
], (ResourceView, KeyboardAddWidgetView, KeyboardFieldDisplayView,
  DateFieldDisplayView, EntererFieldDisplayView, ModifierFieldDisplayView,
  globals) ->

  # Keyboard View
  # -------------
  #
  # For displaying individual keyboards.

  class KeyboardView extends ResourceView

    focus: ->

    turnOnPrimaryDataTooltip: ->

    showAndHighlightOnlyMe: ->

    render: ->
      if globals.unicodeCharMap
        super
      else
        @fetchUnicodeData(=> @render())

    resourceName: 'keyboard'

    resourceAddWidgetView: KeyboardAddWidgetView

    getHeaderTitle: -> "Keyboard “#{@model.get 'name'}”"

    # Attributes that are always displayed.
    primaryAttributes: [
      # 'name'
      'keyboard'
      'description'
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
      keyboard: KeyboardFieldDisplayView


