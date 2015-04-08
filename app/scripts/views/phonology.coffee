define [
  './resource'
  './phonology-add-widget'
  './person-field-display'
  './date-field-display'
], (ResourceView, PhonologyAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView) ->

  # Phonology View
  # --------------
  #
  # For displaying individual phonologies.

  class PhonologyView extends ResourceView

    resourceName: 'phonology'

    resourceAddWidgetView: PhonologyAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'script'
      'compile_succeeded'
      'compile_message'
      'compile_attempt'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'UUID'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView

