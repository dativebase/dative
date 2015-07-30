define [
  './resource'
  './elicitation-method-add-widget'
  './date-field-display'
  './field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, ElicitationMethodAddWidgetView, DateFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView) ->

  # Elicitation Method View
  # -----------------------
  #
  # For displaying individual elicitation methods.

  class ElicitationMethodView extends ResourceView

    resourceName: 'elicitationMethod'

    resourceAddWidgetView: ElicitationMethodAddWidgetView

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


