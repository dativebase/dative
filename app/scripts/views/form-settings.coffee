define [
  './settings'
  './parser-task-set'
  './../utils/globals'
], (SettingsView, ParserTaskSetView, globals) ->

  # Form Settings View
  # ------------------
  #
  # View for a widget for viewing and modifying the settings of form resources
  # in the system.
  #
  # Form resources can use morphological parsers, phonologies, and/or
  # morphologies in order to automate the valuation of specified fields based
  # on the values of other specified fields. See `ParserTaskSetModel` for
  # details.

  class FormSettingsView extends SettingsView

    initialize: (options) ->
      super options
      @parserTaskSetViewVisible = false
      @events['click button.toggle-parser-task-set'] =
        'toggleParserSettings'
      @parserTaskSetViewInitialized = false
      @parserTaskSetViewRendered = false

    getFieldCategoryNames: -> [
      'igt'
      'translation'
      'secondary'
      'readonly'
    ]

    getHeaderTitle: -> 'Form Settings'

    render: ->
      super
      @parserSettingsVisibility()
      @

    guify: ->
      super

    initializeParserTaskSetView: ->
      parserTaskSetModel = globals.applicationSettings.get 'parserTaskSet'
      @parserTaskSetView = new ParserTaskSetView model: parserTaskSetModel

    renderParserTaskSetView: ->
      @$('.parser-task-set-container').first()
        .html @parserTaskSetView.render().el
      @rendered @parserTaskSetView

    initializeParserTaskSetViewCheck: ->
      if not @parserTaskSetViewInitialized
        @initializeParserTaskSetView()
        @parserTaskSetViewInitialized = true

    renderParserTaskSetViewCheck: ->
      if not @parserTaskSetViewRendered
        @renderParserTaskSetView()
        @parserTaskSetViewRendered = true

    parserSettingsVisibility: ->
      if @parserTaskSetViewVisible
        @$('.parser-task-set-container').show()
      else
        @$('.parser-task-set-container').hide()
      @setParserTaskSetViewToggleButtonState()

    toggleParserSettings: ->
      if @parserTaskSetViewVisible
        @parserTaskSetViewVisible = false
        @$('.parser-task-set-container').slideUp()
      else
        @prep()
        @parserTaskSetViewVisible = true
        @$('.parser-task-set-container').slideDown()
      @setParserTaskSetViewToggleButtonState()

    setParserTaskSetViewToggleButtonState: ->
      if @parserTaskSetViewVisible
        @$('button.toggle-parser-task-set i')
          .removeClass 'fa-caret-right'
          .addClass 'fa-caret-down'
      else
        @$('button.toggle-parser-task-set i')
          .removeClass 'fa-caret-down'
          .addClass 'fa-caret-right'

    prep: ->
      @initializeParserTaskSetViewCheck()
      @renderParserTaskSetViewCheck()

