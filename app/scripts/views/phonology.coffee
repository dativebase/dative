define [
  './resource'
  './phonology-controls'
  './phonology-add-widget'
  './person-field-display'
  './date-field-display'
  './boolean-icon-display'
  './script-display'
], (ResourceView, PhonologyControlsView, PhonologyAddWidgetView,
  PersonFieldDisplayView, DateFieldDisplayView, BooleanIconFieldDisplayView,
  ScriptFieldDisplayView) ->

  # Phonology View
  # --------------
  #
  # For displaying individual phonologies.

  class PhonologyView extends ResourceView

    resourceName: 'phonology'

    keydown: (event) ->
      super event
      switch event.which
        when 67
          if not @addUpdateResourceWidgetHasFocus()
            @$('button.compile').click()
        when 82
          if not @addUpdateResourceWidgetHasFocus()
            @$('button.run-tests').click()
        when 191
          if not @addUpdateResourceWidgetHasFocus()
            @$('textarea[name=apply-down]').first().focus()

    excludedActions: ['history', 'data']

    controlsViewClass: PhonologyControlsView

    resourceAddWidgetView: PhonologyAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'compile_succeeded'
      'compile_message'
      'compile_attempt'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'UUID'
      'id'
      'script'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      compile_succeeded: BooleanIconFieldDisplayView
      script: ScriptFieldDisplayView

