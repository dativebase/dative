define [
  './base'
  './subcorpus-add-widget'
  './field-display'
  './object-with-name-field-display'
  './date-field-display'
  './person-field-display'
  './array-of-objects-with-name-field-display'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/subcorpus'
], (BaseView, SubcorpusAddWidgetView, FieldDisplayView,
  ObjectWithNameFieldDisplayView, DateFieldDisplayView, PersonFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, globals, tooltips,
  subcorpusTemplate) ->

  # Subcorpus View
  # --------------
  #
  # For displaying individual subcorpora (OLD corpora).

  class SubcorpusView extends BaseView

    template: subcorpusTemplate
    tagName: 'div'
    className: 'dative-subcorpus-widget dative-shadowed-widget
      dative-paginated-item dative-widget-center ui-widget ui-widget-content
      ui-corner-all'

    initialize: (options) ->
      @headerTitle = options.headerTitle or ''
      @activeServerType = @getActiveServerType()
      @setState options
      @addUpdateType = @getUpdateViewType()
      @updateView = new SubcorpusAddWidgetView
        model: @model,
        addUpdateType: @addUpdateType
      @updateViewRendered = false

    getUpdateViewType: -> if @model.get('id') then 'update' else 'add'

    # Render the Add a Subcorpus view.
    renderUpdateView: ->
      @updateView.setElement @$('.update-subcorpus-widget').first()
      @updateView.render()
      @updateViewRendered = true
      @rendered @updateView

    # Set the state of the subcorpus display: what is visible.
    setState: (options) ->
      defaults =
        primaryDataLabelsVisible: false # labels for primary data fields
        expanded: false
        headerVisible: false # the header full of buttons
        secondaryDataVisible: false # comments, tags, etc.
        updateViewVisible: false
      _.extend defaults, options
      for key, value of defaults
        @[key] = value
      @effectuateExpanded()

    # `expanded` is a higher-level setting, controlling header and secondary
    # data visibility.
    effectuateExpanded: ->
      if @expanded
        @headerVisible = true
        @secondaryDataVisible = true
      else
        @headerVisible = false
        @secondaryDataVisible = false

    listenToEvents: ->
      super
      @listenTo Backbone, 'subcorpus:dehighlightAllSubcorpusViews', @dehighlight
      @listenTo Backbone, 'subcorporaView:expandAllSubcorpora', @expand
      @listenTo Backbone, 'subcorporaView:collapseAllSubcorpora', @collapse
      @listenTo Backbone, 'subcorporaView:showAllLabels',
        @hidePrimaryContentAndLabelsThenShowAll
      @listenTo Backbone, 'subcorporaView:hideAllLabels',
        @hidePrimaryContentAndLabelsThenShowContent
      @listenTo Backbone, 'deleteSubcorpus', @delete
      @listenTo @updateView, 'subcorpusAddView:hide', @hideUpdateViewAnimate
      @listenTo @model, 'change', @indicateModelState
      @listenTo @updateView, 'forceModelChanged', @indicateModelState
      @listenTo @model, 'updateSubcorpusSuccess', @indicateModelIsUnaltered

    indicateModelState: ->
      if @updateView.modelAltered()
        @indicateModelIsAltered()
      else
        @indicateModelIsUnaltered()

    indicateModelIsAltered: ->
      @$('.dative-widget-header').addClass 'ui-state-error'
      headerTitleHTML = "#{@headerTitle} (<i class='fa fa-fw
        fa-exclamation-triangle'></i>Unsaved changes)"
      @$('.dative-widget-header-title').first()
        .html headerTitleHTML

    indicateModelIsUnaltered: ->
      @$('.dative-widget-header').removeClass 'ui-state-error'
      @$('.dative-widget-header-title').first().html @headerTitle

    events:
      'click .subcorpus-primary-data': 'showAndHighlightOnlyMe'
      'mouseenter .subcorpus-primary-data': 'mouseenterPrimaryData'
      'mouseleave .subcorpus-primary-data': 'mouseleavePrimaryData'
      'click .hide-subcorpus-details': 'hideSubcorpusDetails'
      'click .hide-subcorpus-widget': 'hideSubcorpusWidget'
      'click .toggle-secondary-data': 'toggleSecondaryDataAnimate'
      'click .toggle-primary-data-labels': 'togglePrimaryDataLabelsAnimate'
      'focus': 'focus'
      'focusout': 'focusout'
      'keydown': 'keydown'
      'click .update-subcorpus': 'update'
      'click .duplicate-subcorpus': 'duplicate'
      'click .delete-subcorpus': 'deleteConfirm'
      'click .export-subcorpus': 'exportSubcorpus'

    exportSubcorpus: ->
      Backbone.trigger 'openExporterDialog', model: @model

    update: ->
      @showUpdateViewAnimate()

    duplicate: ->
      Backbone.trigger 'duplicateSubcorpusConfirm', @model

    # Trigger opening of a confirm dialog: if user clicks "Ok", then this
    # subcorpus will be deleted.
    deleteConfirm: (event) ->
      if event then @stopEvent event
      id = @model.get 'id'
      options =
        text: "Do you really want to delete the subcorpus with id “#{id}”?"
        confirm: true
        confirmEvent: 'deleteSubcorpus'
        confirmArgument: id
      Backbone.trigger 'openAlertDialog', options

    # Really delete this subcorpus.
    # This is triggered by the "delete subcorpus" confirm dialog when the user
    # clicks "Ok".
    delete: (subcorpusId) ->
      if subcorpusId is @model.get('id')
        @model.collection.destroySubcorpus @model

    render: ->
      @getDisplayViews()
      @html()
      @renderDisplayViews()
      @guify()
      @listenToEvents()
      @renderUpdateView()
      @

    getDisplayViews: ->
      @getPrimaryDisplayViews()
      @getSecondaryDisplayViews()

    primaryAttributes: [
      'name'
      'description'
    ]

    secondaryAttributes: [
      'content'
      'tags'
      'form_search'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'files'
      'UUID'
      'id'
    ]

    # Put the appropriate DisplayView instances in `@primaryDisplayViews`.
    getPrimaryDisplayViews: ->
      @primaryDisplayViews = []
      for attribute in @primaryAttributes
        @primaryDisplayViews.push @getDisplayView attribute

    getSecondaryDisplayViews: ->
      @secondaryDisplayViews = []
      for attribute in @secondaryAttributes
        @secondaryDisplayViews.push @getDisplayView attribute

    attribute2displayView:
      tags: ArrayOfObjectsWithNameFieldDisplayView
      form_search: ObjectWithNameFieldDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

    # Return the appropriate DisplayView (subclass) instance for a given
    # attribute, as specified in `@attribute2displayView`. The default display
    # view is `FieldDisplayView`.
    getDisplayView: (attribute) ->
      # All `DisplayView` subclasses expect `attribute` and `model` on init.
      params =
        resource: 'subcorpora'
        attribute: attribute # e.g., "name"
        model: @model
      if attribute of @attribute2displayView
        MyDisplayView = @attribute2displayView[attribute]
        new MyDisplayView params
      else # the default display view is FieldDisplayView
        new FieldDisplayView params

    html: ->
      @$el
        .attr 'tabindex', 0
        .html @template(
          activeServerType: @activeServerType
          headerTitle: @headerTitle
          addUpdateType: @addUpdateType
        )

    # TODO: do this all in one DOM-manipulation event via a single document
    # fragment, if possible.
    renderDisplayViews: ->
      @renderPrimaryDisplayViews()
      @renderSecondaryDisplayViews()

    renderPrimaryDisplayViews: ->
      container = document.createDocumentFragment()
      for displayView in @primaryDisplayViews
        container.appendChild displayView.render().el
        @rendered displayView
      @$('div.subcorpus-primary-data').append container

    renderSecondaryDisplayViews: ->
      container = document.createDocumentFragment()
      for displayView in @secondaryDisplayViews
        container.appendChild displayView.render().el
        @rendered displayView
      @$('div.subcorpus-secondary-data').append container

    guify: ->
      @primaryDataLabelsVisibility()
      @guifyButtons()
      @headerVisibility()
      @secondaryDataVisibility()
      @updateViewVisibility()

    # Make the header visible, or not, depending on state.
    headerVisibility: ->
      if @headerVisible
        @showHeader()
        @turnOffPrimaryDataTooltip()
      else
        @hideHeader()
        @turnOnPrimaryDataTooltip()

    # Make the secondary data visible, or not, depending on state.
    secondaryDataVisibility: ->
      if @secondaryDataVisible
        @showSecondaryData()
      else
        @hideSecondaryData()

    # Make the update view visible, or not, depending on state.
    updateViewVisibility: ->
      if @updateViewVisible
        @showUpdateView()
      else
        @hideUpdateView()

    # Hide/show the labels for the primary data, e.g., transcription/utterance,
    # translation(s), etc.
    togglePrimaryDataLabelsAnimate: ->
      if @primaryDataLabelsVisible
        @hidePrimaryContentAndLabelsThenShowContent()
      else
        @hidePrimaryContentAndLabelsThenShowAll()

    # Fade out primary data, then fade in primary data and labels.
    hidePrimaryContentAndLabelsThenShowAll: ->
      @$(@primaryDataContentSelector).fadeOut
        complete: =>
          @showPrimaryDataLabelsAnimate()
          @showPrimaryDataContentAnimate()
          @$(@primaryDataContentSelector).removeClass 'no-label'

    # Fade out primary data and labels, then fade in primary data.
    hidePrimaryContentAndLabelsThenShowContent: ->
      @hidePrimaryDataLabelsAnimate()
      @$(@primaryDataContentSelector).fadeOut
        complete: =>
          @showPrimaryDataContentAnimate()
          @$(@primaryDataContentSelector).addClass 'no-label'

    # Fade in primary data content.
    showPrimaryDataContentAnimate: ->
      @$(@primaryDataContentSelector).fadeIn()

    # "Show labels" button.
    setPrimaryDataLabelsButtonStateClosed: ->
      @$('.toggle-primary-data-labels')
        .find 'i.fa'
          .removeClass 'fa-toggle-on'
          .addClass 'fa-toggle-off'
          .end()
        .button()
        .tooltip
          items: 'button'
          content: 'show labels'

    # "Hide labels" button.
    setPrimaryDataLabelsButtonStateOpen: ->
      @$('.toggle-primary-data-labels')
        .find 'i.fa'
          .removeClass 'fa-toggle-off'
          .addClass 'fa-toggle-on'
          .end()
        .button()
        .tooltip
          items: 'button'
          content: 'hide labels'

    primaryDataLabelsSelector: '.dative-field-display-label-container'

    primaryDataContentSelector: '.dative-field-display-representation-container'

    # Show the labels for the primary data (e.g., transcription, utterance) attributes.
    showPrimaryDataLabelsAnimate: ->
      @primaryDataLabelsVisible = true
      @setPrimaryDataLabelsButtonStateOpen()
      @$(@primaryDataLabelsSelector).fadeIn().css('display', 'inline-block')

    # Hide the labels for the primary data (e.g., transcription, utterance) attributes.
    hidePrimaryDataLabelsAnimate: (event) ->
      @primaryDataLabelsVisible = false
      @setPrimaryDataLabelsButtonStateClosed()
      @$(@primaryDataLabelsSelector).fadeOut()

    # Make the primary data visible, or not, depending on state.
    primaryDataLabelsVisibility: ->
      if @primaryDataLabelsVisible
        @showPrimaryDataLabels()
      else
        @hidePrimaryDataLabels()

    # Toggle the visibility of the primary data labels.
    togglePrimaryDataLabels: ->
      if @primaryDataLabelsVisible
        @hidePrimaryDataLabels()
      else
        @showPrimaryDataLabels()

    hidePrimaryDataLabels: ->
      @primaryDataLabelsVisible = false
      @setPrimaryDataLabelsButtonStateClosed()
      @$(@primaryDataLabelsSelector).hide()
      @$(@primaryDataContentSelector).addClass 'no-label'

    showPrimaryDataLabels: ->
      @primaryDataLabelsVisible = true
      @setPrimaryDataLabelsButtonStateOpen()
      @$(@primaryDataLabelsSelector).show().css 'display', 'inline-block'
      @$(@primaryDataContentSelector).removeClass 'no-label'

    # jQueryUI-ify <button>s
    guifyButtons: ->

      @$('button.hide-subcorpus-details, button.hide-subcorpus-widget')
        .button()
        .tooltip
          items: 'button'
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.toggle-secondary-data')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

      @$('button.toggle-primary-data-labels')
        .button()
        .tooltip
          position:
            my: "right-80 center"
            at: "left center"
            collision: "flipfit"

      # Make all of righthand-side buttons into jQuery buttons and set the
      # position of their tooltips programmatically.
      @$(@$('.button-container-right button').get().reverse())
        .each (index, element) =>
          leftOffset = (index * 35) + 10
          @$(element)
            .button()
            .tooltip
              position:
                my: "left+#{leftOffset} center"
                at: "right center"
                collision: "flipfit"

    # Button for toggling secondary data: when secondary data are hidden.
    setSecondaryDataButtonStateClosed: ->
      @$('.toggle-secondary-data')
        .find('i')
          .removeClass('fa-angle-up')
          .addClass('fa-angle-down')
          .end()
        .button()
        .tooltip
          items: 'button'
          content: 'show the secondary data of this subcorpus'

    # Button for toggling secondary data: when secondary data are visible.
    setSecondaryDataButtonStateOpen: ->
      @$('.toggle-secondary-data')
        .find('i')
          .removeClass('fa-angle-down')
          .addClass('fa-angle-up')
          .end()
        .button()
        .tooltip
          items: 'button'
          content: 'hide the secondary data of this subcorpus'

    setUpdateButtonStateOpen: -> @$('.update-subcorpus').button 'disable'

    setUpdateButtonStateClosed: -> @$('.update-subcorpus').button 'enable'

    # Expand the subcorpus view: show buttons and secondary data.
    expand: ->
      @showSecondaryDataEvent = 'subcorpus:subcorpusExpanded' # SubcorporaView listens for this once in order to scroll to the correct place
      @showFullAnimate()

    # Collapse the subcorpus view: hide buttons and secondary data.
    collapse: ->
      @hideSecondaryDataEvent = 'subcorpus:subcorpusCollapsed' # SubcorporaView listens for this once in order to scroll to the correct place
      @hideFullAnimate()

    # Highlight the subcorpus view and show its secondary data.
    highlightAndShow: ->
      @highlight()
      @showSecondaryData()

    # Highlight self, show self's extra data, tell other subcorpus views to dehighlight themselves.
    showAndHighlightOnlyMe: ->
      if not @headerVisible
        @showFullAnimate()
        @highlightOnlyMe()

    highlight: ->
      @$el.addClass 'ui-state-highlight'

    highlightOnlyMe: ->
      @dehighlightAll()
      @highlight()

    dehighlightAll: ->
      Backbone.trigger 'subcorpus:dehighlightAllSubcorpusViews'

    dehighlight: ->
      @$el.removeClass 'ui-state-highlight'

    dehighlightAndHide: ->
      @dehighlight()
      @hideSecondaryData()

    focus: ->
      @highlightOnlyMe()

    focusout: ->
      @dehighlight()

    # <Enter> on a closed subcorpus opens it, <Esc> on an open subcorpus closes
    # it.
    keydown: (event) ->
      switch event.which
        when 27
          if @addUpdateType is 'add'
            @hideSubcorpusWidget()
          else if @headerVisible
            @hideSubcorpusDetails()
        when 13
          if not @headerVisible
            @showFullAnimate()
        when 85 # "u" for "update"
          if not @addUpdateSubcorpusWidgetHasFocus()
            @$('.update-subcorpus').first().click()
        when 68 # "d" for "delete"
          if not @addUpdateSubcorpusWidgetHasFocus()
            @$('.delete-subcorpus').first().click()
        when 69 # "e" for "export"
          if not @addUpdateSubcorpusWidgetHasFocus()
            @$('.export-subcorpus').first().click()

    ############################################################################
    # Hide & Show stuff
    ############################################################################

    # Hide details and self-focus. Clicking on the double-angle-up
    # (hide-subcorpus-details) button calls this, as does `@keydown` with <Esc>.
    hideSubcorpusDetails: ->
      @hideFullAnimate()
      @$el.focus()

    # Hide details and then completely hide self. Clicking on the X
    # (hide-subcorpus-widget) button calls this, as does `@keydown` with <Esc>.
    hideSubcorpusWidget: ->
      @trigger 'newSubcorpusView:hide'

    # Full = border, header & secondary data
    ############################################################################

    showFull: ->
      @addBorder()
      @turnOffPrimaryDataTooltip()
      @showHeader()
      @showSecondaryData()

    hideFull: ->
      @removeBorder()
      @turnOnPrimaryDataTooltip()
      @hideHeader()
      @hideSecondaryData()

    showFullAnimate: ->
      @addBorderAnimate()
      @turnOffPrimaryDataTooltip()
      @showHeaderAnimate()
      @showSecondaryDataAnimate()

    hideFullAnimate: ->
      @removeBorderAnimate()
      @turnOnPrimaryDataTooltip()
      @hideHeaderAnimate()
      @hideSecondaryDataAnimate()
      @hideUpdateViewAnimate()

    # Header
    ############################################################################

    showHeader: ->
      @headerVisible = true
      @$('.dative-widget-header').first().show()

    hideHeader: ->
      @headerVisible = false
      @$('.dative-widget-header').first().hide()

    showHeaderAnimate: ->
      @headerVisible = true
      @$('.dative-widget-header').first().slideDown()

    hideHeaderAnimate: ->
      @headerVisible = false
      @$('.dative-widget-header').first().slideUp()

    # Secondary Data
    ############################################################################

    showSecondaryData: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorder()
      @$('.subcorpus-secondary-data').show()

    hideSecondaryData: ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @removeBorder()
      @$('.subcorpus-secondary-data').hide()

    toggleSecondaryData: ->
      if @secondaryDataVisible
        @hideSecondaryData()
      else
        @showSecondaryData()

    showSecondaryDataAnimate: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorderAnimate()
      @$('.subcorpus-secondary-data').slideDown
        complete: =>
          # SubcorporaView listens once for this and fixes scroll position and focus in response
          if @showSecondaryDataEvent
            Backbone.trigger @showSecondaryDataEvent
            @showSecondaryDataEvent = null

    hideSecondaryDataAnimate: (event) ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @$('.subcorpus-secondary-data').slideUp
        complete: =>
          # SubcorporaView listens once for this and fixes scroll position and focus in response
          if @hideSecondaryDataEvent
            Backbone.trigger @hideSecondaryDataEvent
            @hideSecondaryDataEvent = null

    toggleSecondaryDataAnimate: ->
      if @secondaryDataVisible
        @hideSecondaryDataAnimate()
      else
        @showSecondaryDataAnimate()


    # Update View
    ############################################################################

    showUpdateView: ->
      if not @updateViewRendered then @renderUpdateView()
      @updateViewVisible = true
      @setUpdateButtonStateOpen()
      @$('.update-subcorpus-widget').show
        complete: =>
          @showFull()
          Backbone.trigger 'addSubcorpusWidgetVisible'
          @focusFirstUpdateViewTextarea()

    hideUpdateView: ->
      @updateViewVisible = false
      @setUpdateButtonStateClosed()
      @$('.update-subcorpus-widget').hide()

    toggleUpdateView: ->
      if @updateViewVisible
        @hideUpdateView()
      else
        @showUpdateView()

    showUpdateViewAnimate: ->
      if not @updateViewRendered then @renderUpdateView()
      @updateViewVisible = true
      @setUpdateButtonStateOpen()
      @$('.update-subcorpus-widget').slideDown
        complete: =>
          @showFullAnimate()
          Backbone.trigger 'addSubcorpusWidgetVisible'
          @focusFirstUpdateViewTextarea()

    focusFirstUpdateViewTextarea: ->
      @$('.update-subcorpus-widget textarea').first().focus()

    hideUpdateViewAnimate: ->
      @updateViewVisible = false
      @setUpdateButtonStateClosed()
      @$('.update-subcorpus-widget').slideUp
        complete: => @$el.focus()

    toggleUpdateViewAnimate: ->
      if @updateViewVisible
        @hideUpdateViewAnimate()
      else
        @showUpdateViewAnimate()


    # Border
    ############################################################################

    addBorder: ->
      @$el
        .css 'border-color': @constructor.jQueryUIColors().defBo
        .addClass 'expanded'

    removeBorder: ->
      @$el
        .css 'border-color': 'transparent'
        .removeClass 'expanded'

    addBorderAnimate: ->
      @$el
        .animate 'border-color': @constructor.jQueryUIColors().defBo
        .addClass 'expanded'

    removeBorderAnimate: ->
      @$el
        .animate 'border-color': 'transparent'
        .removeClass 'expanded'


    # Primary Data
    ############################################################################

    mouseenterPrimaryData: ->
      if not @headerVisible
        @$('.subcorpus-primary-data').css 'cursor', 'pointer'
      else
        @$('.subcorpus-primary-data').css 'cursor', 'text'

    mouseleavePrimaryData: ->
      if not @headerVisible
        @$('.subcorpus-primary-data').css 'cursor', 'text'

    # The subcorpus display representations in the primary data section have
    # tooltips only when the buttons and secondary data are hidden.
    turnOnPrimaryDataTooltip: ->
      @$('.dative-field-display-representation-container').each (index, element) =>
        $element = @$ element
        if not $element.tooltip 'instance'
          $element
            .tooltip
              open: (event, ui) -> ui.tooltip.css "max-width", "200px"
              items: 'div'
              content: 'Click here for controls and more data.'
              position:
                my: 'right-10 center'
                at: 'left center'
                collision: 'flipfit'

    turnOffPrimaryDataTooltip: ->
      @$('.dative-field-display-representation-container').each (index, element) =>
        $element = @$ element
        if $element.tooltip 'instance' then $element.tooltip 'destroy'

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'


    ############################################################################
    # General template helpers
    ############################################################################

    styleDisplayNone: ' style="display: none;" '

    # Return an in-line CSS style to hide the HTML of an empty subcorpus attribute
    # Note the use of `=>` so that the ECO template knows to use this view's
    # context.
    displayNoneStyle: (value) =>
      if _.isDate(value) or _.isNumber(value)
        ''
      else if _.isEmpty(value) or @isValueless(value)
        @styleDisplayNone
      else
        ''

    # Returns `true` only if thing is an object all of whose values are either
    # `null` or empty strings.
    isValueless: (thing) ->
      _.isObject(thing) and
      (not _.isArray(thing)) and
      _.isEmpty(_.filter(_.values(thing), (x) -> x isnt null and x isnt ''))

