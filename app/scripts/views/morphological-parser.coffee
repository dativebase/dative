define [
  './resource'
  './morphological-parser-extra-actions'
  './morphological-parser-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './boolean-icon-display'
], (ResourceView, MorphologicalParserExtraActionsView,
  MorphologicalParserAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  BooleanIconFieldDisplayView) ->

  # Morphological Parser View
  # -------------------------
  #
  # For displaying individual morphological parsers.

  class MorphologicalParserView extends ResourceView

    resourceName: 'morphologicalParser'

    initialize: (options) ->
      console.clear() # For development purposes, can be removed later.
      super options
      @events['click .resource-actions'] = 'toggleExtraActionsViewAnimate'
      @extraActionsView = new MorphologicalParserExtraActionsView(model: @model)
      @extraActionsViewRendered = false
      @resourceNameHumanReadable = =>
        @utils.camel2regular @resourceName

    listenToEvents: ->
      super
      @listenTo @extraActionsView, "extraActionsView:hide",
        @hideExtraActionsViewAnimate

    guify: ->
      super
      @extraActionsViewVisibility()

    resourceAddWidgetView: MorphologicalParserAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'phonology'
      'morphology'
      'language_model'
      'generate_succeeded'
      'generate_message'
      'generate_attempt'
      'compile_succeeded'
      'compile_message'
      'compile_attempt'
      'morphology_rare_delimiter'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'id'
      'UUID'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      phonology: ObjectWithNameFieldDisplayView
      morphology: ObjectWithNameFieldDisplayView
      language_model: ObjectWithNameFieldDisplayView
      generate_succeeded: BooleanIconFieldDisplayView
      compile_succeeded: BooleanIconFieldDisplayView

    # An array of actions that are not relevant to this resource, e.g.,
    # 'update', 'delete', 'export', 'history'.
    excludedActions: [
      'history'
    ]

    setState: (options) ->
      options.extraActionsViewVisible = false
      super options


    # Extra Actions View
    ############################################################################

    # Make the extra actions view visible, or not, depending on state.
    extraActionsViewVisibility: ->
      if @extraActionsViewVisible
        @showExtraActionsView()
      else
        @hideExtraActionsView()

    setExtraActionsButtonStateOpen: -> @$('.resource-actions').button 'disable'

    setExtraActionsButtonStateClosed: -> @$('.resource-actions').button 'enable'

    # Render the extra actions view.
    renderExtraActionsView: ->
      @extraActionsView.setElement @$('.resource-actions-widget').first()
      @extraActionsView.render()
      @extraActionsViewRendered = true
      @rendered @extraActionsView

    showExtraActionsView: ->
      if not @extraActionsViewRendered then @renderExtraActionsView()
      @extraActionsViewVisible = true
      @setExtraActionsButtonStateOpen()
      @$('.resource-actions-widget').first().show
        complete: =>
          @showFull()
          Backbone.trigger "add#{@resourceNameCapitalized}WidgetVisible"
          @focusFirstExtraActionsViewTextarea()

    hideExtraActionsView: ->
      @extraActionsViewVisible = false
      @setExtraActionsButtonStateClosed()
      @$('.resource-actions-widget').first().hide()

    toggleExtraActionsView: ->
      if @extraActionsViewVisible
        @hideExtraActionsView()
      else
        @showExtraActionsView()

    showExtraActionsViewAnimate: ->
      if not @extraActionsViewRendered then @renderExtraActionsView()
      @extraActionsViewVisible = true
      @setExtraActionsButtonStateOpen()
      @$('.resource-actions-widget').first().slideDown
        complete: =>
          @showFullAnimate()
          Backbone.trigger "showExtraActionsViewVisible"
          @focusFirstExtraActionsViewTextarea()

    focusFirstExtraActionsViewTextarea: ->
      @$('.resource-actions-widget textarea').first().focus()

    hideExtraActionsViewAnimate: ->
      @extraActionsViewVisible = false
      @setExtraActionsButtonStateClosed()
      @$('.resource-actions-widget').first().slideUp
        complete: => @$el.focus()

    toggleExtraActionsViewAnimate: ->
      if @extraActionsViewVisible
        @hideExtraActionsViewAnimate()
      else
        @showExtraActionsViewAnimate()

