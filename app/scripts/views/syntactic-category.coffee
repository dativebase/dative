define [
  './resource'
  './syntactic-category-add-widget'
  './date-field-display'
  './field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, SyntacticCategoryAddWidgetView, DateFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView) ->

  # Syntactic Category View
  # -----------------------
  #
  # For displaying individual syntactic categories.

  class SyntacticCategoryView extends ResourceView

    resourceName: 'syntacticCategory'

    resourceAddWidgetView: SyntacticCategoryAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: []

    # Attributes that may be hidden.
    secondaryAttributes: [
      'name'
      'type'
      'description'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView

