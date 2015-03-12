define [
  './form-handler-base'
  './textarea-field'
  './select-field'
  './required-select-field'
  './person-select-field'
  './user-select-field'
  './source-select-field'
  './transcription-grammaticality-field'
  './utterance-judgement-field'
  './translations-field'
  './comments-field'
  './date-field'
  './multiselect-field'
  './../models/form'
  './../utils/globals'
  './../templates/form-add-widget'
  'multiselect'
  'jqueryelastic'
], (FormHandlerBaseView, TextareaFieldView, SelectFieldView,
  RequiredSelectFieldView, PersonSelectFieldView, UserSelectFieldView,
  SourceSelectFieldView, TranscriptionGrammaticalityFieldView,
  UtteranceJudgementFieldView, TranslationsFieldView, CommentsFieldView,
  DateFieldView, MultiselectFieldView, FormModel, globals, formAddTemplate) ->

  # Form Add Widget View
  # --------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # form and updating an existing one. Currently this view is being
  # used as a sub-view of the "forms browse" page view.
  #
  # (Note: the page-level view `FormAddView` is currently not being used and
  # may be removed entirely.)

  # TODO/Questions:
  #
  # 1. Should we valuate the following attributes in Dative or can we leave this
  #    for the FieldDB web services?:
  #    - datetimeEntered
  #    - datetimeModified
  #    - enterer
  #    - modifier
  #    (Note: the OLD will just ignore these attributes if we send them and will
  #    valuate them itself. I am unsure of FieldDB's behaviour wrt this.)
  #
  # 2. FieldDB tags field should use magicsuggest:
  #    - See https://github.com/jrwdunham/dative/issues/98
  #
  # 3. Are there inconsistencies in the data structures of `Datum.comments`
  #    across FieldDB corpora? (Some exploration suggested that there were ...)
  #
  # 4. FieldDB `modifiedByUser`: does this form have to modify this array or will
  #    the FieldDB corpus service do it?
  #
  # 5. Use `morphemeBreakIds`, and `morphemeGlossIds` in the OLD form display for
  #    morpho-lexical cross-referencing. (Note: these are OLD-specific and are
  #    generated server-side.)

  class FormAddWidgetView extends FormHandlerBaseView

    template: formAddTemplate
    className: 'add-form-widget dative-widget-center ui-widget
      ui-widget-content ui-corner-all'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @secondaryDataVisible = false
      @listenToEvents()
      @addUpdateType = options.addUpdateType or 'add'

    render: ->
      if @activeServerTypeIsOLD() and not @weHaveOLDNewFormData()
        @model.getOLDNewFormData() # Success in this request will call `@render()`
        return
      @getFieldViews()
      @html()
      @secondaryDataVisibility()
      @renderFieldViews()
      @guify()
      @fixRoundedBorders() # defined in BaseView
      @listenToEvents()
      @

    events:
      'click button.add-form-button':              'submitForm'
      'click button.hide-form-add-widget':         'hideSelf'
      'click button.toggle-secondary-data-fields': 'toggleSecondaryDataAnimate'
      'click .form-add-help':                      'openFormAddHelp'

    listenToEvents: ->
      super
      # Events specific to an OLD backend and the request for the data needed to create a form.
      @listenTo Backbone, 'getOLDNewFormDataStart', @getOLDNewFormDataStart
      @listenTo Backbone, 'getOLDNewFormDataEnd', @getOLDNewFormDataEnd
      @listenTo Backbone, 'getOLDNewFormDataSuccess', @getOLDNewFormDataSuccess
      @listenTo Backbone, 'getOLDNewFormDataFail', @getOLDNewFormDataFail
      @listenToFieldViews()

    listenToFieldViews: ->
      for fieldView in @fieldViews()
        @listenTo fieldView, 'submit', @submitForm
        @listenTo fieldView, 'focusPreviousField', @focusPreviousField

    # Write the initial HTML to the page.
    html: ->
      context =
        addUpdateType: @addUpdateType
        headerTitle: @getHeaderTitle()
        activeServerType: @getActiveServerType()
      @$el.html @template(context)

    getHeaderTitle: ->
      if @addUpdateType is 'add'
        'Add a Form'
      else
        'Update this form'

    submitForm: (event) ->
      console.log 'submitForm called'
      @stopEvent event
      @setToModel()

    # Set the state of the "add a form" HTML form on the Dative form model.
    setToModel: -> fv.setToModel() for fv in @fieldViews()

    # Focus the previous field. This is a hack that is required because the
    # multiSelect does not correctly move the focuse on a Shift+Tab event.
    focusPreviousField: ->
      $focusedElement = @$ ':focus'
      inputSelector = 'textarea, .ms-list, .ui-selectmenu-button, button'
      $focusedElement
        .closest('li.dative-form-field')
        .prev()
          .find(inputSelector).first().focus()

    # Tell the Help dialog to open itself and search for "adding a form" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openFormAddHelp: ->
      if @addUpdateType is 'add'
        searchTerm = 'adding a form'
      else
        searchTerm = 'updating a form'
      Backbone.trigger(
        'helpDialog:toggle',
        searchTerm: searchTerm
        scrollToIndex: 1
      )

    activeServerTypeIsOLD: -> @getActiveServerType() is 'OLD'

    primaryDataSelector: 'ul.primary-data'

    secondaryDataSelector: 'ul.secondary-data'


    ############################################################################
    # Getting, configuring & rendering field sub-views
    ############################################################################

    # Maps attributes to their appropriate FieldView subclasses.
    # This is where field-specific configuration should go.
    attribute2fieldView:
      FieldDB:
        utterance:          UtteranceJudgementFieldView
        comments:           CommentsFieldView
      OLD:
        transcription:      TranscriptionGrammaticalityFieldView
        translations:       TranslationsFieldView
        elicitation_method: SelectFieldView
        syntactic_category: SelectFieldView
        speaker:            PersonSelectFieldView
        elicitor:           UserSelectFieldView
        verifier:           UserSelectFieldView
        source:             SourceSelectFieldView
        status:             RequiredSelectFieldView
        date_elicited:      DateFieldView
        tags:               MultiselectFieldView

    # Return the appropriate FieldView (subclass) instance for a given
    # attribute, as specified in `@attribute2fieldView`. The default field view
    # is `FieldView`.
    getFieldView: (attribute) ->
      params = # All `FieldView` subclasses expect `attribute` and `model` on init
        attribute: attribute # e.g., "transcription"
        model: @model # `FieldView` subclasses expect a form model
        options: @getOptions() # These are the OLD <select> options (N/A for FieldDB)
      if attribute of @attribute2fieldView[@activeServerType]
        MyFieldView = @attribute2fieldView[@activeServerType][attribute]
        new MyFieldView params
      else # the default field view is a(n expandable) textarea.
        new TextareaFieldView params

    # Put the appropriate FieldView instances in `@primaryFieldViews` and.
    # `@secondaryFieldViews`
    getFieldViews: ->
      @getPrimaryFieldViews()
      @getSecondaryFieldViews()

    # Put the appropriate FieldView instances in `@primaryFieldViews`.
    getPrimaryFieldViews: ->
      @primaryFieldViews = []
      igtAttributes = @getFormAttributes @activeServerType, 'igt'
      translationAttributes = @getFormAttributes @activeServerType, 'translation'
      for attribute in igtAttributes.concat translationAttributes
        @primaryFieldViews.push @getFieldView attribute

    # Put the appropriate FieldView instances in `@secondaryFieldViews`.
    getSecondaryFieldViews: ->
      @secondaryFieldViews = []
      secondaryAttributes = @getEditableSecondaryAttributes()
      for attribute in secondaryAttributes
        @secondaryFieldViews.push @getFieldView attribute

    fieldViews: ->
      try
        @primaryFieldViews.concat @secondaryFieldViews
      catch
        []

    # Return a crucially ordered array of editable secondary data attributes.
    # Note: the returned array is defined using the
    # (to-be-user/system-specified) array defined in the `applicationSettings`
    # model.
    getEditableSecondaryAttributes: ->
      switch @activeServerType
        when 'FieldDB' then @getFieldDBEditableSecondaryAttributes()
        when 'OLD' then @getOLDEditableSecondaryAttributes()

    # Return a crucially ordered array of editable OLD form attributes.
    # An OLD form attribute is editable and secondary iff:
    # - it is secondary, as specified in the app settings model AND
    # - it is not read-only (as also specified in the app settings model)
    getOLDEditableSecondaryAttributes: ->
      secondaryAttributes = @getFormAttributes @activeServerType, 'secondary'
      readonlyAttributes = @getFormAttributes @activeServerType, 'readonly'
      (a for a in secondaryAttributes when a not in readonlyAttributes)

    # Return a crucially ordered array of editable FieldDB datum attributes
    # (where an attribute may be just that or it may be the `label` value of a
    # session/datum field). A datum attribute is editable and secondary iff:
    # - it is a datum field or it is `datum.comments` AND
    # - it is not read-only (see app settings model) AND
    # - it is not "primary" (i.e., IGT, translation or grammaticality, as
    #   defined in app settings)
    # The idea is that we display fields for the secondary attributes (if
    # possible) in the order specified in the app settings model and then we
    # display input fields for any remaining (non-primary and non-secondary and
    # editable) attributes.
    getFieldDBEditableSecondaryAttributes: ->

      # Get the list of *possible* editable secondary attributes: datumField
      # labels and `comments`.
      # TODO: this should also include other "direct" datum attributes, such as
      # audioVideo.
      datumFieldLabels = (field.label for field in @model.get('datumFields'))
      possibleEditableSecondaryAttributes = datumFieldLabels.concat ['comments']

      # `secondaryAttributes` is the ordered list of datum attributes that are
      # specified as "secondary" in the applicationSettings model.
      orderedSecondaryAttributes = @getFormAttributes 'FieldDB', 'secondary'
      orderedEditableSecondaryAttributes = (a for a in \
        orderedSecondaryAttributes when a in \
        possibleEditableSecondaryAttributes)

      # These attributes can NOT be editable secondary attributes.
      # (Note: these arrays are all defined in the application settings model.)
      unavailableAttributes = [].concat(
        @getFormAttributes 'FieldDB', 'readonly'
        @getFormAttributes 'FieldDB', 'igt'
        @getFormAttributes 'FieldDB', 'grammaticality'
        @getFormAttributes 'FieldDB', 'translation'
      )

      otherSecondaryAttributes = (a for a in \
        possibleEditableSecondaryAttributes when a not in \
        orderedEditableSecondaryAttributes)
      secondaryAttributes = orderedEditableSecondaryAttributes
        .concat otherSecondaryAttributes
      (a for a in secondaryAttributes when a not in unavailableAttributes)

    renderFieldViews: ->
      @renderPrimaryFieldViews()
      @renderSecondaryFieldViews()

    renderPrimaryFieldViews: ->
      $primaryDataUL = @$ 'ul.primary-data'
      for fieldView in @primaryFieldViews
        $primaryDataUL.append fieldView.render().el
        @rendered fieldView

    renderSecondaryFieldViews: ->
      $secondaryDataUL = @$ @secondaryDataSelector
      for fieldView in @secondaryFieldViews
        $secondaryDataUL.append fieldView.render().el
        @rendered fieldView


    ############################################################################
    # OLD input options (i.e., possible speakers, users, categories, etc.)
    ############################################################################

    # Returns true of `globals` has a key for `oldData`. The value of this key is
    # an object containing speakers, users, grammaticalities, tags, etc.
    weHaveOLDNewFormData: -> globals.oldData?

    # Return an object representing the options for forced-choice inputs.
    # Currently only relevant for the OLD.
    getOptions: ->
      if globals.oldData
        @addOLDStatuses globals.oldData
      else
        {}

    # Add to `options` the possible values for the OLD's `form.status`.
    # NOTE: this is a client-side patch: this information should be provided by
    # the OLD web service and returned in the call to GET /forms/new.
    addOLDStatuses: (options) ->
      options.statuses = []
      for status in ['tested', 'requires testing']
        options.statuses.push id: status, name: status
      options

    getOLDNewFormDataStart: -> @spin()

    getOLDNewFormDataEnd: -> @stopSpin()

    getOLDNewFormDataSuccess: (data) ->
      globals.oldData = data
      @render()

    getOLDNewFormDataFail: ->
      console.log 'Failed to retrieve the data from the OLD server which is
        necessary for creating a new form'


    ############################################################################
    # jQuery (UI) GUI stuff.
    ############################################################################

    # Make the vanilla HTML nice and jQueryUI-ified.
    guify: ->
      @buttonify()
      @tooltipify()

    # Make the buttons into jQuery buttons.
    buttonify: ->
      @$('.dative-widget-header button').button()
      @$('.button-only-fieldset button').button()

    # Make the `title` attributes of the inputs/controls into jQueryUI tooltips.
    tooltipify: ->
      @$('.dative-widget-header .hide-form-add-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-widget-header .toggle-secondary-data-fields.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-70')
      @$('.dative-widget-header .form-add-help.dative-tooltip')
        .tooltip position: @tooltipPositionRight('+20')
      @$('button.add-form-button')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('ul.button-only-fieldset button.toggle-secondary-data-fields')
        .tooltip position: @tooltipPositionLeft('-90')


    ############################################################################
    # Showing, hiding and toggling
    ############################################################################

    # The FormsView will handle this hiding.
    hideSelf: -> @trigger 'formAddView:hide'

    # If the secondary data fields should be visible, show them; otherwise no.
    secondaryDataVisibility: ->
      if @secondaryDataVisible
        @showSecondaryData()
      else
        @hideSecondaryData()

    hideSecondaryData: ->
      @secondaryDataVisible = false
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).hide()

    showSecondaryData: ->
      @secondaryDataVisible = true
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).show()

    hideSecondaryDataAnimate: ->
      @secondaryDataVisible = false
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).slideUp()

    showSecondaryDataAnimate: ->
      @secondaryDataVisible = true
      @setSecondaryDataToggleButtonState()
      @$(@secondaryDataSelector).slideDown
        complete: =>
          @$(@secondaryDataSelector).find('textarea').first().focus()

    toggleSecondaryData: ->
      if @secondaryDataVisible
        @hideSecondaryData()
      else
        @showSecondaryData()

    toggleSecondaryDataAnimate: ->
      if @secondaryDataVisible
        @hideSecondaryDataAnimate()
      else
        @showSecondaryDataAnimate()

    # Make the "toggle secondary data" button have the appropriate icon and tooltip.
    setSecondaryDataToggleButtonState: ->
      if @secondaryDataVisible
        @$('button.toggle-secondary-data-fields')
          .tooltip
            content: 'hide the secondary data input fields'
          .find('i')
            .removeClass 'fa-angle-down'
            .addClass 'fa-angle-up'
      else
        @$('button.toggle-secondary-data-fields')
          .tooltip
            content: 'show the secondary data input fields'
          .find('i')
            .removeClass 'fa-angle-up'
            .addClass 'fa-angle-down'

    # Create a FieldDB datum model using `FieldDB`.
    # NOTE: this method is currently not being used: `setToModel` and the
    # same-named method in the `FieldView` sub-classes handle setting to the
    # Dative model for both the OLD and FieldDB cases.
    setFieldDBDatum: (modelObject) ->
      tobesaved = new FieldDB.Document modelObject
      #tobesaved.dbname = tobesaved.application.currentFieldDB.dbname
      #tobesaved.url = "#{tobesaved.application.currentFieldDB.url}/#{tobesaved.dbname}"
      #tobesaved.save()

