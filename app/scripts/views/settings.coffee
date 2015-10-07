define [
  './base'
  './../utils/globals'
  './../templates/settings'
], (BaseView, globals, settingsTemplate) ->

  # Settings View
  # -------------
  #
  # View for viewing and altering the settingsof a resource. At the moment, the
  # settings simply govern which attribute fields are visible.

  class SettingsView extends BaseView

    template: settingsTemplate
    className: 'settings-widget dative-widget-center
      dative-shadowed-widget ui-widget ui-widget-content ui-corner-all'

    initialize: (options) ->
      @resourceName = options.resourceName or 'form'
      @resourceNamePlural = @utils.pluralize @resourceName
      @iTriggeredVisibilityChange = false
      @resourceName = options?.resourceName or ''
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    listenToEvents: ->
      super
      @listenTo Backbone, 'fieldVisibilityChange', @fieldVisibilityChange

    # This is triggered when this settings view (or another one) changes the
    # visibility setting of a resource field. If we triggered this event, we
    # don't do anything but reset our "I triggered this event" state. Otherwise
    # we sync our display with the current app settings state.
    fieldVisibilityChange: (resource, fieldName, visibilityValue) ->
      if @utils.pluralize(@resourceName) is resource
        if @iTriggeredVisibilityChange
          @iTriggeredVisibilityChange = false
        else
          @$("select[name=#{fieldName}]")
            .val visibilityValue
            .selectmenu 'refresh'
          if visibilityValue is 'hidden'
            @$("div.attribute-name.attribute-#{@utils.snake2hyphen fieldName}")
              .addClass 'hidden'
          else if visibilityValue is 'visible'
            @$("div.attribute-name.attribute-#{@utils.snake2hyphen fieldName}")
              .removeClass 'hidden'

    events:
      'click button.hide-settings-widget': 'hideSelf'
      'keydown':                           'keydown'
      'click button.settings-help':        'openSettingsHelp'
      'selectmenuchange':                  'visibilitySettingChanged'

    # When the user changes the selectmenu value for a field, we alter the
    # `hidden` array for that resource in `globals.applicationSettings`
    # accordingly.
    visibilitySettingChanged: (event) ->
      $target = @$ event.target
      name = $target.attr 'name'
      value = $target.val()
      try
        hiddenFields = globals.applicationSettings
          .get('resources')[@resourceNamePlural]
          .fieldsMeta[@activeServerType].hidden
        if value is 'hidden'
          @$("div.attribute-name.attribute-#{@utils.snake2hyphen name}")
            .addClass 'hidden'
          if name not in hiddenFields
            hiddenFields.push name
        else if value is 'visible'
          @$("div.attribute-name.attribute-#{@utils.snake2hyphen name}")
            .removeClass 'hidden'
          if name in hiddenFields
            hiddenFields.splice(hiddenFields.indexOf(name), 1)
        globals.applicationSettings.save()
        @iTriggeredVisibilityChange = true
        Backbone.trigger 'fieldVisibilityChange', @resourceNamePlural, name, value
      catch
        console.log "unable to access the fields metadata for
          #{@resourceNamePlural}"

    # Tell the Help dialog to open itself and search for
    # "<resource-name-plural> settings" and scroll to the second match. WARN:
    # this is brittle because if the help HTML changes, then the second match
    # may not be what we want...
    openSettingsHelp: ->
      searchTerm = "#{@utils.snake2regular @resourceName} settings"
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: searchTerm
        scrollToIndex: 1
      )

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    getFieldCategories: ->
      try
        globals.applicationSettings.get('resources')[@resourceNamePlural]
          .fieldsMeta[@activeServerType]
      catch
        {}

    # Sub-classes should redefine this method so that it returns an array of
    # category names that are the keys of an object in the global application
    # settings model. For example, form fields are categorized into 'igt'
    # fields, 'secondary' fields, etc.
    getFieldCategoryNames: -> []

    # Return a (case-insensitively) sorted list of the fields of the resource
    # that this settings view is for. Note that these are the *displayable*
    # fields, not all the fields; e.g., fields like `form.morpheme_break_ids`
    # are absent.
    getResourceFields: (fieldCategories) ->
      resourceFields = {}
      for categoryName in @getFieldCategoryNames()
        for field in fieldCategories[categoryName]
          resourceFields[field] = null
      resourceFields = _.keys(resourceFields)
        .sort (a, b) -> a.toLowerCase().localeCompare(b.toLowerCase())

    html: ->
      fieldCategories = @getFieldCategories()
      context =
        resourceName: @resourceName
        headerTitle: 'Settings'
        activeServerType: @activeServerType
        resourceFields: @getResourceFields fieldCategories
        utils: @utils
        fieldCategories: fieldCategories
      @$el.html @template(context)

    guify: ->
      @fixRoundedBorders() # defined in BaseView
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo
      @$('button').button()
      @$('.attribute-visibility select').selectmenu width: '100%'
      @tooltipify()

    tooltipify: ->
      @$('.button-container-right .dative-tooltip')
        .tooltip position: @tooltipPositionRight('+20')
      @$('.button-container-left .dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

    # The resource super-view will handle this hiding.
    hideSelf: -> @trigger "settingsView:hide"

    # ESC hides the settings widget
    keydown: (event) ->
      event.stopPropagation()
      switch event.which
        when 27
          @stopEvent event
          @hideSelf()

    spinnerOptions: (top='50%', left='-170%') ->
      options = super
      options.top = top
      options.left = left
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: (selector='.spinner-container', top='50%', left='-170%') ->
      @$(selector).spin @spinnerOptions(top, left)

    stopSpin: (selector='.spinner-container') ->
      @$(selector).spin false

