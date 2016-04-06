define [
  './old-application-settings-resource'
  './old-application-settings-add-widget'
  './input-validation-controls'
  './../utils/globals'
], (OLDApplicationSettingsResourceView, OLDApplicationSettingsAddWidgetView,
  InputValidationControlsView, globals) ->

  class InputValidationAddWidgetView extends OLDApplicationSettingsAddWidgetView

    getHeaderTitle: ->
      if @addUpdateType is 'add'
        "Add Input Validation settings"
      else
        "Update the Input Validation settings"

    # Tell the Help dialog to open itself and search for "adding a resource" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openResourceAddHelp: (event) ->
      if event then @stopEvent event
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "input validation settings"
        scrollToIndex: 1
      )

    getContext: ->
      context = super
      context.resourceNameHuman = 'Input Validation settings'
      context

    getHeaderTitle: -> 'Update the Input Validation settings'

    # Attributes that are always displayed.
    primaryAttributes: [
      'orthographic_validation'
      'storage_orthography'
      #'input_orthography'

      'narrow_phonetic_validation'
      'narrow_phonetic_inventory'

      'broad_phonetic_validation'
      'broad_phonetic_inventory'

      'morpheme_break_validation'
      'morpheme_break_is_orthographic'
      'phonemic_inventory'
      'morpheme_delimiters'

      'punctuation'
      'grammaticalities'
    ]

    spacerIndices: -> [2, 4, 6, 10]


  class InputValidationView extends OLDApplicationSettingsResourceView

    resourceNameHumanReadable: => 'Input Validation settings'

    # Users should not be able to delete or duplicate an OLD application
    # settings resource.
    excludedActions: [
      'history'  # forms have this, since everything is version controlled.
      'data'     # file resources have this, for accessing their file data.
      'delete'
      'duplicate'
      'settings'
      'export'
    ]

    controlsViewClass: InputValidationControlsView

    resourceAddWidgetView: InputValidationAddWidgetView

    getHeaderTitle: ->
      if globals.applicationSettings.get 'loggedIn'
        activeServer = globals.applicationSettings.get 'activeServer'
        activeServerName = activeServer.get 'name'
      else
        activeServerName = null
      if @model.get 'object_language_name'
        name = @model.get 'object_language_name'
        if activeServerName
          "Input Validation for the OLD server “#{activeServerName}”"
        else
          "Input Validation for the OLD server for language #{name}"
      else
        "Input Validation for an OLD server"
        if activeServerName
          "Input Validation for the OLD server “#{activeServerName}”"
        else
          'Input Validation for an OLD server'

    # Attributes that are always displayed.
    primaryAttributes: [
      'orthographic_validation'
      'storage_orthography'
      #'input_orthography'

      'narrow_phonetic_validation'
      'narrow_phonetic_inventory'

      'broad_phonetic_validation'
      'broad_phonetic_inventory'

      'morpheme_break_validation'
      'morpheme_break_is_orthographic'
      'phonemic_inventory'
      'morpheme_delimiters'

      'punctuation'
      'grammaticalities'
    ]

    spacerIndices: -> [2, 4, 6, 10]

