define [
  './base'
  './../utils/globals'
  './../templates/settings'
], (BaseView, globals, settingsTemplate) ->

  # Settings View
  # -------------
  #
  # View for viewing and altering the settings of a resource. At the moment, the
  # settings simply govern which attribute fields are visible.

  class SettingsView extends BaseView

    template: settingsTemplate
    className: 'settings-widget dative-widget-center
      dative-shadowed-widget ui-widget ui-widget-content ui-corner-all'

    initialize: (options) ->
      @resourceName = options.resourceName or 'form'
      @resourceNamePlural = @utils.pluralize @resourceName
      @iTriggeredVisibilityChange = false
      @iTriggeredStickinessChange = false
      @resourceName = options?.resourceName or ''
      @activeServerType = @getActiveServerType()
      @attributeVisibilitiesVisible = false
      @listenToEvents()

    listenToEvents: ->
      super
      @listenTo Backbone, 'fieldVisibilityChange', @fieldVisibilityChange
      @listenTo Backbone, 'attributeStickinessChange', @attributeStickinessChange

    # This is triggered when this settings view (or another one) changes the
    # stickiness setting of a resource attribute (i.e., field). If we triggered
    # this event, we don't do anything but reset our "I triggered this event"
    # state. Otherwise we sync our display with the current app settings state.
    attributeStickinessChange: (resource) ->
      if @utils.pluralize(@resourceName) is resource
        if @iTriggeredStickinessChange
          @iTriggeredStickinessChange = false
        else
          stickyAttributes = @getStickyAttributes()
          @$('i.stickiness-checkbox').each (i, e) =>
            if @$(e).data('attr') in stickyAttributes
              @$(e)
                .addClass 'fa-check-square'
                .removeClass 'fa-square'
            else
              @$(e)
                .addClass 'fa-square'
                .removeClass 'fa-check-square'

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
      'click .stickiness-checkbox':        'stickinessChanged'
      'click button.toggle-attribute-visibilities':
        'toggleAttributeVisibilities'
      'click button.toggle-sticky-attributes': 'toggleAttributeStickinesses'

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

    # The user has clicked on a "change attribute stickiness" checkbox.
    stickinessChanged: (event) ->
      $target = @$ event.target
      attribute = $target.data 'attr'
      stickyAttributes = @getStickyAttributes()
      if $target.hasClass 'fa-square'
        $target
          .removeClass 'fa-square'
          .addClass 'fa-check-square'
      else
        $target
          .removeClass 'fa-check-square'
          .addClass 'fa-square'
      @setStickyAttributes()

    setStickyAttributes: ->
      resourceMeta = globals.applicationSettings
        .get('resources')[@resourceNamePlural]
      if resourceMeta
        resourceMeta.stickyAttributes = []
        @$('.stickiness-checkbox').each (i, e) =>
          if @$(e).hasClass 'fa-check-square'
            resourceMeta.stickyAttributes.push @$(e).data('attr')
        globals.applicationSettings.save()
        @iTriggeredStickinessChange = true
        Backbone.trigger 'attributeStickinessChange', @resourceNamePlural

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
      @attributeVisibilitiesVisibility()
      @attributeStickinessesVisibility()
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

    # Return the array of form attribute names that are specified as "sticky"
    # in application settings.
    getStickyAttributes: ->
      resourceMeta = globals.applicationSettings
        .get('resources')[@resourceNamePlural]
      if resourceMeta
        # If our app setting is missing this attribute (because it is from an
        # older version of Dative), we add it here.
        if 'stickyAttributes' not of resourceMeta
          resourceMeta.stickyAttributes = []
          globals.applicationSettings.save()
        resourceMeta.stickyAttributes
      else
        []

    # Return the array of form attribute names that are *may* be specified as
    # "sticky" in application settings.
    getPossiblyStickyAttributes: ->
      resourceMeta = globals.applicationSettings
        .get('resources')[@resourceNamePlural]
      if resourceMeta
        # If our app setting is missing this attribute (because it is from an
        # older version of Dative), we add it here.
        if 'possiblyStickyAttributes' not of resourceMeta
          resourceMeta.possiblyStickyAttributes = [
            'date_elicited'
            'elicitation_method'
            'elicitor'
            'source'
            'speaker'
            'status'
            'syntactic_category'
            'tags'
          ]
          globals.applicationSettings.save()
        resourceMeta.possiblyStickyAttributes
      else
        []

    getHeaderTitle: -> 'Settings'

    html: ->
      fieldCategories = @getFieldCategories()
      context =
        resourceName: @resourceName
        resourceNamePlural: @resourceNamePlural
        headerTitle: @getHeaderTitle()
        activeServerType: @activeServerType
        resourceFields: @getResourceFields fieldCategories
        utils: @utils
        fieldCategories: fieldCategories
        stickyAttributes: @getStickyAttributes()
        possiblyStickyAttributes: @getPossiblyStickyAttributes()
      @$el.html @template(context)

    guify: ->
      @fixRoundedBorders() # defined in BaseView
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo
      @$('.attribute-visibilities-attributes,.sticky-attributes-attributes')
        .css 'border-color': @constructor.jQueryUIColors().defBo
      @$('button').button()
      @$('select').selectmenu width: 'auto'
      @tooltipify()

    tooltipify: ->
      @$('.button-container-right .dative-tooltip')
        .tooltip position: @tooltipPositionRight('+20')
      @$('.button-container-left .dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-widget-body .dative-tooltip')
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

    attributeVisibilitiesVisibility: ->
      if @attributeVisibilitiesVisible
        @$('.attribute-visibilities-attributes').show()
      else
        @$('.attribute-visibilities-attributes').hide()
      @setAttributeVisibilitiesToggleButtonState()

    toggleAttributeVisibilities: ->
      if @attributeVisibilitiesVisible
        @attributeVisibilitiesVisible = false
        @$('.attribute-visibilities-attributes').slideUp()
      else
        @attributeVisibilitiesVisible = true
        @$('.attribute-visibilities-attributes').slideDown()
      @setAttributeVisibilitiesToggleButtonState()

    setAttributeVisibilitiesToggleButtonState: ->
      if @attributeVisibilitiesVisible
        @$('button.toggle-attribute-visibilities i')
          .removeClass 'fa-caret-right'
          .addClass 'fa-caret-down'
      else
        @$('button.toggle-attribute-visibilities i')
          .removeClass 'fa-caret-down'
          .addClass 'fa-caret-right'

    attributeStickinessesVisibility: ->
      if @attributeStickinessesVisible
        @$('.sticky-attributes-attributes').show()
      else
        @$('.sticky-attributes-attributes').hide()
      @setAttributeStickinessesToggleButtonState()

    toggleAttributeStickinesses: ->
      if @attributeStickinessesVisible
        @attributeStickinessesVisible = false
        @$('.sticky-attributes-attributes').slideUp()
      else
        @attributeStickinessesVisible = true
        @$('.sticky-attributes-attributes').slideDown()
      @setAttributeStickinessesToggleButtonState()

    setAttributeStickinessesToggleButtonState: ->
      if @attributeStickinessesVisible
        @$('button.toggle-sticky-attributes i')
          .removeClass 'fa-caret-right'
          .addClass 'fa-caret-down'
      else
        @$('button.toggle-sticky-attributes i')
          .removeClass 'fa-caret-down'
          .addClass 'fa-caret-right'

