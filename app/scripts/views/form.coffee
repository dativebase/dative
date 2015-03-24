define [
  'backbone'
  './form-handler-base'
  './form-add-widget'
  './field-display'
  './phonetic-transcription-field-display'
  './grammaticality-value-field-display'
  './judgement-value-field-display'
  './morpheme-break-field-display'
  './morpheme-gloss-field-display'
  './translations-field-display'
  './object-with-name-field-display'
  './source-field-display'
  './date-field-display'
  './person-field-display'
  './array-of-objects-with-title-field-display'
  './array-of-objects-with-name-field-display'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/form'
], (Backbone, FormHandlerBaseView, FormAddWidgetView, FieldDisplayView,
  PhoneticTranscriptionFieldDisplayView, GrammaticalityValueFieldDisplayView,
  JudgementValueFieldDisplayView, MorphemeBreakFieldDisplayView,
  MorphemeGlossFieldDisplayView, TranslationsFieldDisplayView,
  ObjectWithNameFieldDisplayView, SourceFieldDisplayView, DateFieldDisplayView,
  PersonFieldDisplayView, ArrayOfObjectsWithTitleFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, globals, tooltips, formTemplate) ->

  # Form View
  # ---------
  #
  # For displaying individual forms with an IGT interface.

  class FormView extends FormHandlerBaseView

    template: formTemplate
    tagName: 'div'
    className: 'dative-form-widget dative-widget-center ui-widget
      ui-widget-content ui-corner-all'

    initialize: (options) ->
      @headerTitle = options.headerTitle or ''
      @activeServerType = @getActiveServerType()
      @setState options
      @addUpdateType = @getUpdateViewType()
      @updateView = new FormAddWidgetView
        model: @model,
        addUpdateType: @addUpdateType
      @updateViewRendered = false
      @originalModelCopy = @model.clone()

    getUpdateViewType: -> if @model.get('id') then 'update' else 'add'

    # Render the Add a Form view.
    renderUpdateView: ->
      @updateView.setElement @$('.update-form-widget').first()
      @updateView.render()
      @updateViewRendered = true
      @rendered @updateView

    # Set the state of the form display: what is visible.
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
      @listenTo Backbone, 'form:dehighlightAllFormViews', @dehighlight
      @listenTo Backbone, 'formsView:expandAllForms', @expand
      @listenTo Backbone, 'formsView:collapseAllForms', @collapse
      @listenTo Backbone, 'formsView:showAllLabels',
        @hidePrimaryContentAndLabelsThenShowAll
      @listenTo Backbone, 'formsView:hideAllLabels',
        @hidePrimaryContentAndLabelsThenShowContent
      @listenTo Backbone, 'deleteForm', @delete
      @listenTo @updateView, 'formAddView:hide', @hideUpdateViewAnimate
      @listenTo @model, 'change', @modelChanged

    modelChanged: ->
      if @modelAltered()
        @$('.dative-widget-header').addClass 'ui-state-error'
        @$('.dative-widget-header-title').first().text 'unsaved changes'
      else
        @$('.dative-widget-header').removeClass 'ui-state-error'
        @$('.dative-widget-header-title').first().text @headerTitle

    modelAltered: -> not _.isEqual @originalModelCopy.attributes, @model.attributes

    events:
      'click .form-primary-data': 'showAndHighlightOnlyMe'
      'mouseenter .form-primary-data': 'mouseenterPrimaryData'
      'mouseleave .form-primary-data': 'mouseleavePrimaryData'
      'click .hide-form-details': 'hideFormDetails'
      'click .hide-form-widget': 'hideFormWidget'
      'click .toggle-secondary-data': 'toggleSecondaryDataAnimate'
      'click .toggle-primary-data-labels': 'togglePrimaryDataLabelsAnimate'
      'focus': 'focus'
      'focusout': 'focusout'
      'keydown': 'keydown'
      'click .update-form': 'update'
      'click .duplicate-form': 'duplicate'
      'click .delete-form': 'deleteConfirm'

    update: ->
      @showUpdateViewAnimate()

    duplicate: ->
      Backbone.trigger 'duplicateFormConfirm', @model

    # Trigger opening of a confirm dialog: if user clicks "Ok", then this
    # form will be deleted.
    deleteConfirm: (event) ->
      if event then @stopEvent event
      id = @model.get 'id'
      options =
        text: "Do you really want to delete the form with id “#{id}”?"
        confirm: true
        confirmEvent: 'deleteForm'
        confirmArgument: id
      Backbone.trigger 'openAlertDialog', options

    # Really delete this form.
    # This is triggered by the "delete form" confirm dialog when the user
    # clicks "Ok".
    delete: (formId) ->
      if formId is @model.get('id')
        @model.collection.destroyOLDForm @model

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

    # Put the appropriate DisplayView instances in `@primaryDisplayViews`.
    getPrimaryDisplayViews: ->
      @igtDisplayViews = []
      igtAttributes = @getFormAttributes @activeServerType, 'igt'
      for attribute in igtAttributes
        @igtDisplayViews.push @getDisplayView attribute
      @translationDisplayViews = []
      translationAttributes = @getFormAttributes @activeServerType, 'translation'
      for attribute in translationAttributes
        @translationDisplayViews.push @getDisplayView attribute

    getSecondaryDisplayViews: ->
      @secondaryDisplayViews = []
      secondaryAttributes = @getFormAttributes @activeServerType, 'secondary'
      for attribute in secondaryAttributes
        @secondaryDisplayViews.push @getDisplayView attribute

    # TODO: FieldDB array-type fields:
    # 'comments':           'fieldDBCommentsFieldDisplay' # direct Datum attribute
    # 'modifiedByUser':     'fieldDBModifiersArrayFieldDisplay'

    attribute2displayView:
      FieldDB:
        utterance: JudgementValueFieldDisplayView
        morphemes: MorphemeBreakFieldDisplayView
        gloss: MorphemeGlossFieldDisplayView
        dateElicited: DateFieldDisplayView
        dateEntered: DateFieldDisplayView
        dateModified: DateFieldDisplayView
      OLD:
        narrow_phonetic_transcription: PhoneticTranscriptionFieldDisplayView
        phonetic_transcription: PhoneticTranscriptionFieldDisplayView
        transcription: GrammaticalityValueFieldDisplayView
        translations: TranslationsFieldDisplayView
        morpheme_break: MorphemeBreakFieldDisplayView
        morpheme_gloss: MorphemeGlossFieldDisplayView
        syntactic_category: ObjectWithNameFieldDisplayView
        elicitation_method: ObjectWithNameFieldDisplayView
        source: SourceFieldDisplayView
        date_elicited: DateFieldDisplayView
        datetime_entered: DateFieldDisplayView
        datetime_modified: DateFieldDisplayView
        speaker: PersonFieldDisplayView
        elicitor: PersonFieldDisplayView
        enterer: PersonFieldDisplayView
        modifier: PersonFieldDisplayView
        verifier: PersonFieldDisplayView
        collections: ArrayOfObjectsWithTitleFieldDisplayView
        tags: ArrayOfObjectsWithNameFieldDisplayView
        files: ArrayOfObjectsWithNameFieldDisplayView

    # Maps attributes to their appropriate DisplayView subclasses.
    # This is where field-specific configuration should go.
    # attribute2displayView_:
    #   FieldDB:
    #     utterance:          UtteranceJudgementDisplayView
    #     comments:           CommentsDisplayView
    #   OLD:
    #     transcription:      TranscriptionGrammaticalityDisplayView
    #     translations:       TranslationsDisplayView
    #     elicitation_method: SelectDisplayView
    #     syntactic_category: SelectDisplayView
    #     speaker:            PersonSelectDisplayView
    #     elicitor:           UserSelectDisplayView
    #     verifier:           UserSelectDisplayView
    #     source:             SourceSelectDisplayView
    #     status:             RequiredSelectDisplayView
    #     date_elicited:      DateDisplayView
    #     tags:               MultiselectDisplayView

    # Return the appropriate DisplayView (subclass) instance for a given
    # attribute, as specified in `@attribute2displayView`. The default display view
    # is `DisplayView`.
    getDisplayView: (attribute) ->
      params = # All `DisplayView` subclasses expect `attribute` and `model` on init
        attribute: attribute # e.g., "transcription"
        model: @model # `DisplayView` subclasses expect a form model
      if attribute of @attribute2displayView[@activeServerType]
        MyDisplayView = @attribute2displayView[@activeServerType][attribute]
        new MyDisplayView params
      else # the default display view is FieldDisplayView
        new FieldDisplayView params

    html: ->
      @$el
        .attr
          'id': @model.cid
          'tabindex': 0
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
      @renderIGTDisplayViews()
      @renderTranslationDisplayViews()

    renderIGTDisplayViews: ->
      container = document.createDocumentFragment()
      for displayView in @igtDisplayViews
        container.appendChild displayView.render().el
        @rendered displayView
      @$('div.form-igt-data').append container

    renderTranslationDisplayViews: ->
      container = document.createDocumentFragment()
      for displayView in @translationDisplayViews
        container.appendChild displayView.render().el
        @rendered displayView
      @$('div.form-translations-data').append container

    renderSecondaryDisplayViews: ->
      container = document.createDocumentFragment()
      for displayView in @secondaryDisplayViews
        container.appendChild displayView.render().el
        @rendered displayView
      @$('div.form-secondary-data').append container

    # Get the context object for the template.
    # Note that a lot of the heavy lifting is done in methods of this FormView,
    # these are the attributes of `@h.fieldDB` and `@h.old` defined below.
    getContext: ->
      context = _.extend(@model.toJSON(), {
        activeServerType: @activeServerType
        headerTitle: @headerTitle
        h: # "h" for "helpers"
          getFormAttributes: @getFormAttributes
          fieldDB:
            getFieldDBFormAttributeDisplayer: @getFieldDBFormAttributeDisplayer
            alreadyDisplayedFields: @fieldDBAlreadyDisplayedFields()
            fieldDBStringFieldDisplay: @fieldDBStringFieldDisplay
          old:
            getOLDFormAttributeDisplayer: @getOLDFormAttributeDisplayer
      })
      context

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
      @$(@primaryDataLabelsSelector).fadeIn()

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
      @$(@primaryDataLabelsSelector).show()
      @$(@primaryDataContentSelector).removeClass 'no-label'

    # jQueryUI-ify <button>s
    guifyButtons: ->

      @$('button.hide-form-details, button.hide-form-widget')
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
          content: 'show the secondary data of this form'

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
          content: 'hide the secondary data of this form'

    setUpdateButtonStateOpen: -> @$('.update-form').button 'disable'

    setUpdateButtonStateClosed: -> @$('.update-form').button 'enable'

    # Expand the form view: show buttons and secondary data.
    expand: ->
      #@$el.addClass 'expanded'
      @showSecondaryDataEvent = 'form:formExpanded' # FormsView listens for this once in order to scroll to the correct place
      @showFullAnimate()

    # Collapse the form view: hide buttons and secondary data.
    collapse: ->
      #@$el.removeClass 'expanded'
      @hideSecondaryDataEvent = 'form:formCollapsed' # FormsView listens for this once in order to scroll to the correct place
      @hideFullAnimate()

    # Highlight the form view and show its secondary data.
    highlightAndShow: ->
      @highlight()
      @showSecondaryData()

    # Highlight self, show self's extra data, tell other form views to dehighlight themselves.
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
      Backbone.trigger 'form:dehighlightAllFormViews'

    dehighlight: ->
      @$el.removeClass 'ui-state-highlight'

    dehighlightAndHide: ->
      @dehighlight()
      @hideSecondaryData()

    focus: ->
      @highlightOnlyMe()

    focusout: ->
      @dehighlight()

    # <Enter> on a closed form opens it, <Esc> on an open form closes it.
    keydown: (event) ->
      switch event.which
        when 27
          if @addUpdateType is 'add'
            @hideFormWidget()
          else if @headerVisible
            @hideFormDetails()
        when 13
          if not @headerVisible
            @showFullAnimate()
        when 85 # "u" for "update"
          if not @addUpdateFormWidgetHasFocus()
            @$('.update-form').first().click()
        when 68 # "d" for "delete"
          if not @addUpdateFormWidgetHasFocus()
            @$('.delete-form').first().click()

    ############################################################################
    # Hide & Show stuff
    ############################################################################

    # Hide details and self-focus. Clicking on the double-angle-up
    # (hide-form-details) button calls this, as does `@keydown` with <Esc>.
    hideFormDetails: ->
      @hideFullAnimate()
      @$el.focus()

    # Hide details and then completely hide self. Clicking on the X
    # (hide-form-widget) button calls this, as does `@keydown` with <Esc>. TODO: <Esc>
    hideFormWidget: ->
      @trigger 'newFormView:hide'

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
      @$('.form-secondary-data').show()

    hideSecondaryData: ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @removeBorder()
      @$('.form-secondary-data').hide()

    toggleSecondaryData: ->
      if @secondaryDataVisible
        @hideSecondaryData()
      else
        @showSecondaryData()

    showSecondaryDataAnimate: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorderAnimate()
      @$('.form-secondary-data').slideDown
        complete: =>
          # FormsView listens once for this and fixes scroll position and focus in response
          if @showSecondaryDataEvent
            Backbone.trigger @showSecondaryDataEvent
            @showSecondaryDataEvent = null

    hideSecondaryDataAnimate: (event) ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @$('.form-secondary-data').slideUp
        complete: =>
          # FormsView listens once for this and fixes scroll position and focus in response
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
      @$('.update-form-widget').show
        complete: =>
          @showFull()
          Backbone.trigger 'addFormWidgetVisible'
          @focusFirstUpdateViewTextarea()

    hideUpdateView: ->
      @updateViewVisible = false
      @setUpdateButtonStateClosed()
      @$('.update-form-widget').hide()

    toggleUpdateView: ->
      if @updateViewVisible
        @hideUpdateView()
      else
        @showUpdateView()

    showUpdateViewAnimate: ->
      if not @updateViewRendered then @renderUpdateView()
      @updateViewVisible = true
      @setUpdateButtonStateOpen()
      @$('.update-form-widget').slideDown
        complete: =>
          @showFullAnimate()
          Backbone.trigger 'addFormWidgetVisible'
          @focusFirstUpdateViewTextarea()

    focusFirstUpdateViewTextarea: ->
      @$('.update-form-widget textarea').first().focus()

    hideUpdateViewAnimate: ->
      @updateViewVisible = false
      @setUpdateButtonStateClosed()
      @$('.update-form-widget').slideUp
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
        @$('.form-primary-data').css 'cursor', 'pointer'
      else
        @$('.form-primary-data').css 'cursor', 'text'

    mouseleavePrimaryData: ->
      if not @headerVisible
        @$('.form-primary-data').css 'cursor', 'text'

    # The form display representations in the primary data section have
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

    # Return an in-line CSS style to hide the HTML of an empty form attribute
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


    ############################################################################
    # FieldDB-specific template helpers
    ############################################################################

    # The following methods are all responsible for writing FieldDB field
    # labels and values to the DOM.

    # Return the <div> that displays a FieldDB IGT field (e.g., utterance)
    # The `contentCallback` is a function that returns a string representation
    # of the field content; by passing different callbacks to
    # `fieldDBGenericIGTFieldDisplay`, one can build content-specific field
    # representations. This function is called from (functions that are called
    # from) within a template; thus the `context` parameter is the context,
    # i.e., `@` within the template, which has the attributes of
    # `@model.toJSON()`.
    fieldDBGenericIGTFieldDisplay: (attribute, context, contentCallback) =>
      value = @model.getDatumValueSmart attribute
      "<div
        class='form-#{@utils.camel2hyphen attribute}'
        #{@displayNoneStyle value}>
        #{@getFieldDBIGTFieldLabelDiv attribute, context}
        #{@getFieldDBIGTFieldContentDiv attribute, context, contentCallback}
        </div>"

    # Return the <div> that displays an OLD translations field.
    fieldDBGenericTranslationFieldDisplay: (attribute, context, contentCallback) =>
      value = @model.getDatumValueSmart attribute
      "<div
        class='form-#{@utils.camel2hyphen attribute}'
        #{@displayNoneStyle value}>
        #{@getFieldDBTranslationFieldLabelDiv attribute, context}
        #{@getFieldDBTranslationFieldContentDiv attribute, context, contentCallback}
        </div>"

    # Return a <div> containing the label of a FieldDB form field. `type` is "igt"
    # or "secondary".
    getFieldDBFieldLabelDiv: (attribute, context, type) =>
      "<div class='form-#{type}-data-label dative-tooltip'
        title='#{@getFieldDBAttributeTooltip attribute, context}'
        >#{@utils.camel2regular attribute}</div>"

    # Return the <div> containing the label of a FieldDB IGT form field.
    getFieldDBIGTFieldLabelDiv: (attribute, context) =>
      @getFieldDBFieldLabelDiv attribute, context, 'igt'

    # Return the <div> containing the label of a FieldDB translation form field.
    getFieldDBTranslationFieldLabelDiv: (attribute, context) =>
      @getFieldDBFieldLabelDiv attribute, context, 'translation'

    # Return the <div> containing the label of a FieldDB secondary form field.
    getFieldDBSecondaryFieldLabelDiv: (attribute, context) =>
      @getFieldDBFieldLabelDiv attribute, context, 'secondary'

    # Return the <div> containing the content of a FieldDB form field. `type` is
    # "igt" or "secondary".
    getFieldDBFieldContentDiv: (attribute, context, contentCallback, type) =>
      "<div class='form-#{type}-data-content'
        >#{contentCallback attribute, context}</div>"

    # Return the <div> containing the content of a FieldDB IGT form field.
    getFieldDBIGTFieldContentDiv: (attribute, context, contentCallback) =>
      @getFieldDBFieldContentDiv attribute, context, contentCallback, 'igt'

    # Return the <div> containing the content of a FieldDB translation form field.
    getFieldDBTranslationFieldContentDiv: (attribute, context, contentCallback) =>
      @getFieldDBFieldContentDiv attribute, context, contentCallback, 'translation'

    # Return the <div> containing the content of a FieldDB secondary form field.
    getFieldDBSecondaryFieldContentDiv: (attribute, context, contentCallback) =>
      @getFieldDBFieldContentDiv attribute, context, contentCallback, 'secondary'

    # TODO/QUESTION: should the `title` of the session that a datum/form
    # belongs to be displayed among the form's secondary attributes?

    # Utterance with Judgement Field.
    fieldDBUtteranceJudgementFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        value = @model.getDatumValueSmart attribute
        judgement = @fieldDBJudgementConverter @model.getDatumValueSmart('judgement')
        "<span class='judgement'>#{judgement}</span>#{value}"
      @fieldDBGenericIGTFieldDisplay attribute, context, contentCallback

    # Morphemes Field.
    fieldDBMorphemesFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        value = @model.getDatumValueSmart attribute
        @utils.encloseIfNotAlready value, '/', '/'
      @fieldDBGenericIGTFieldDisplay attribute, context, contentCallback

    # Gloss Field.
    # (Potential TODO: small-caps-ify all-caps morpheme abbreviations)
    fieldDBGlossFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @model.getDatumValueSmart(attribute)
      @fieldDBGenericIGTFieldDisplay attribute, context, contentCallback

    # Translation Field. Note that translations are their own category since
    # they are not "secondary" data but they're also not "igt" data.
    fieldDBTranslationFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @model.getDatumValueSmart attribute
      @fieldDBGenericTranslationFieldDisplay attribute, context, contentCallback

    # Map from OLD attribute names to methods defined here that display them.
    oldFormAttribute2Displayer:
      'narrow_phonetic_transcription': 'oldPhoneticTranscriptionFieldDisplay'
      'phonetic_transcription':        'oldPhoneticTranscriptionFieldDisplay'
      'transcription':                 'oldTranscriptionGrammaticalityFieldDisplay'
      'morpheme_break':                'oldMorphemeBreakFieldDisplay'
      'morpheme_gloss':                'oldMorphemeGlossFieldDisplay'
      'translations':                  'oldTranslationsFieldDisplay'
      'elicitation_method':            'oldObjectWithNameFieldDisplay'
      'tags':                          'oldArrayOfObjectsWithNameFieldDisplay'
      'syntactic_category':            'oldObjectWithNameFieldDisplay'
      'date_elicited':                 'oldDateFieldDisplay'
      'speaker':                       'oldPersonFieldDisplay'
      'elicitor':                      'oldPersonFieldDisplay'
      'enterer':                       'oldPersonFieldDisplay'
      'datetime_entered':              'oldDateFieldDisplay'
      'modifier':                      'oldPersonFieldDisplay'
      'datetime_modified':             'oldDateFieldDisplay'
      'verifier':                      'oldPersonFieldDisplay'
      'source':                        'oldSourceFieldDisplay'
      'files':                         'oldArrayOfObjectsWithNameFieldDisplay'
      'collections':                   'oldArrayOfObjectsWithTitleFieldDisplay'

    # Return a "displayer" (a method that generates display HTML) for a FieldDB
    # form attribute.
    getOLDFormAttributeDisplayer: (attribute) =>
      if attribute of @oldFormAttribute2Displayer
        @[@oldFormAttribute2Displayer[attribute]]
      else
        @oldStringFieldDisplay

    # Get Secondary OLD Form Attributes.
    # The returned array defines the order of how the secondary attributes are
    # displayed.
    getOLDFormSecondaryAttributes: ->
      try
        globals.applicationSettings
          .get('oldFormCategories').oldFormSecondaryAttributes
      catch
        []

    # Get IGT OLD Form Attributes.
    # The returned array defines the "IGT" attributes of an OLD form (along
    # with their order). These are those that will be aligned into columns of
    # one word each.
    getOLDFormIGTAttributes: ->
      try
        globals.applicationSettings
          .get('oldFormCategories').oldFormIGTAttributes
      catch
        []

    # Map FieldDB form attributes to displayer method names. Note that most
    # FieldDB attributes are strings and are therefore handled by the default
    # displayer: `@fieldDBStrinfFieldDisplay`.
    fieldDBFormAttribute2Displayer:
      'utterance':          'fieldDBUtteranceJudgementFieldDisplay'
      'morphemes':          'fieldDBMorphemesFieldDisplay'
      'gloss':              'fieldDBGlossFieldDisplay'
      'translation':        'fieldDBTranslationFieldDisplay'
      'comments':           'fieldDBCommentsFieldDisplay' # direct Datum attribute
      'dateElicited':       'fieldDBDateFieldDisplay'     # from `sessionFields`
      'dateEntered':        'fieldDBDateFieldDisplay'     # direct Datum attribute
      'modifiedByUser':     'fieldDBModifiersArrayFieldDisplay'
      'dateModified':       'fieldDBDateFieldDisplay'     # direct Datum attribute

    # Return a "displayer" (a method that generates display HTML) for a FieldDB
    # form attribute.
    getFieldDBFormAttributeDisplayer: (attribute) =>
      if attribute of @fieldDBFormAttribute2Displayer
        @[@fieldDBFormAttribute2Displayer[attribute]]
      else
        @fieldDBStringFieldDisplay

    # Return a list of the Datum attributes that will not be displayed by
    # looping through the defined secondary and IGT attributes.
    fieldDBAlreadyDisplayedFields: =>
      secondaryAttributes = @getFormAttributes 'FieldDB', 'secondary'
      igtAttributes = @getFormAttributes 'FieldDB', 'igt'
      ['judgement', 'translation'].concat secondaryAttributes, igtAttributes

    # Return the <div> that displays a FieldDB Secondary Data field (e.g.,
    # syntacticCategory). The `contentCallback` is a function that returns a
    # string representation of the field content; by passing different
    # callbacks to `fieldDBGenericSecondaryDataFieldDisplay`, one can build
    # content-specific field representations. This function is called from
    # (functions that are called from) within a template; thus the `context`
    # parameter is the context, i.e., `@` within the template, which has the
    # attributes of `@model.toJSON()`.
    fieldDBGenericSecondaryDataFieldDisplay: (attribute, context, contentCallback) =>
      value = @model.getDatumValueSmart attribute
      tooltip = @getFieldDBAttributeTooltip attribute, context
      "<div
        class='form-#{@utils.camel2hyphen attribute}'
        #{@fieldDBDisplayNoneStyle attribute, value}>
        #{@getFieldDBSecondaryFieldLabelDiv attribute, context}
        #{@getFieldDBSecondaryFieldContentDiv attribute, context, contentCallback}
        </div>"

    # Wrap the default `displayNoneStyle` method: account for FieldDB idiosyncracy
    # where we don't want to display `modifiedByUser` if it contains only one
    # element.
    fieldDBDisplayNoneStyle: (attribute, value) =>
      if attribute is 'modifiedByUser'
        try
          if value.length <= 1
            @styleDisplayNone
          else
            ''
        catch
          @styleDisplayNone
      else
        @displayNoneStyle value

    # String Field.
    fieldDBStringFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @model.getDatumValueSmart attribute
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Comments field; schema: {text: '', username: '', timestamp: ''}
    fieldDBCommentsFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        comments = @model.getDatumValueSmart attribute
        result = []
        for comment in comments.reverse()
          result.push "
            <div class='form-fielddb-comment'>
              <span class='form-fielddb-comment-text'>#{comment.text}</span>
              (By <span class='form-fielddb-comment-username'
                >#{comment.username}</span>
              <span class='form-fielddb-comment-timestamp dative-tooltip'
                    title='This comment was made on
                           #{@utils.humanDatetime(new Date(comment.timestamp))}'
              >#{@utils.timeSince(new Date(comment.timestamp))})</span>
            </div>"
        result.join '\n'
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Date(time) Field.
    fieldDBDateFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @utils.timeSince @model.getDatumValueSmart(attribute)
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Modified by user (i.e., modifiers) Field.
    # An array of user objects each of which has four attributes:
    #   appVersion: "2.38.16.07.59ss Fri Jan 16 08:02:30 EST 2015"
    #   gravatar: "5b7145b0f10f7c09be842e9e4e58826d"
    #   timestamp: 1423667274803
    #   username: "jdunham"
    # NOTE: @cesine: I ignore the first modifier object because it is different
    # than the rest: it has no timestamp. I think it just redundantly records
    # the enterer. Am I right about that?
    fieldDBModifiersArrayFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        modifiers = @model.getDatumValueSmart attribute
        result = []
        if modifiers
          try
            for modifier in modifiers.reverse()[...-1]
              timestampSpan = ''
              if modifier.timestamp
                timestampSpan = "
                  <span class='form-fielddb-modifier-timestamp dative-tooltip'
                        title='This modification was made on
                              #{@utils.humanDatetime(new Date(modifier.timestamp))}'
                  >#{@utils.timeSince(new Date(modifier.timestamp))}</span>"
              result.push "
                <div class='form-fielddb-modifier'>
                  <span class='form-fielddb-modifier-username'
                  >#{modifier.username}</span>
                  #{timestampSpan}
                </div>"
            result.join '\n'
          catch e
            console.log "Failed to generate HTML for #{attribute}."
            console.log e
            ''
        else
          ''
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

