define [
  './form-handler-base'
  './textarea-field'
  './relational-select-field'
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
  './../collections/forms'
  './../utils/globals'
  './../templates/form-add-widget'
  'multiselect'
  'jqueryelastic'
], (FormHandlerBaseView, TextareaFieldView, RelationalSelectFieldView,
  RequiredSelectFieldView, PersonSelectFieldView, UserSelectFieldView,
  SourceSelectFieldView, TranscriptionGrammaticalityFieldView,
  UtteranceJudgementFieldView, TranslationsFieldView, CommentsFieldView,
  DateFieldView, MultiselectFieldView, FormModel, FormsCollection, globals,
  formAddTemplate) ->

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

  ##############################################################################
  # Field sub-classes with max lengths
  ##############################################################################

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options

  class TextareaFieldView1023 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 1023
      super options

  class TranscriptionGrammaticalityFieldView255 extends TranscriptionGrammaticalityFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  ##############################################################################
  # Form Add Widget
  ##############################################################################

  class FormAddWidgetView extends FormHandlerBaseView

    template: formAddTemplate
    className: 'add-form-widget dative-widget-center ui-widget
      ui-widget-content ui-corner-all'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @secondaryDataVisible = false
      @listenToEvents()
      @addUpdateType = options.addUpdateType or 'add'
      @submitAttempted = false

      # TODO: if this is an "add"-type form, then the original model copy
      # should (maybe) be an empty form.
      @originalModelCopy = @copyModel @model

    copyModel: (inputModel) ->
      newModel = new FormModel()
      for attr, val of @model.attributes
        newModel.set attr, inputModel.get(attr)
      newModel

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
      'click button.form-add-help':                'openFormAddHelp'
      'click button.clear-form':                   'clear'
      'click button.undo-changes':                 'undoChanges'
      'keydown':                                   'keydown'

    listenToEvents: ->
      super
      # Events specific to an OLD backend and the request for the data needed to create a form.
      @listenTo Backbone, 'getOLDNewFormDataStart', @getOLDNewFormDataStart
      @listenTo Backbone, 'getOLDNewFormDataEnd', @getOLDNewFormDataEnd
      @listenTo Backbone, 'getOLDNewFormDataSuccess', @getOLDNewFormDataSuccess
      @listenTo Backbone, 'getOLDNewFormDataFail', @getOLDNewFormDataFail

      @listenTo @model, 'addOLDFormStart', @addOLDFormStart
      @listenTo @model, 'addOLDFormEnd', @addOLDFormEnd
      @listenTo @model, 'addOLDFormFail', @addOLDFormFail

      @listenTo @model, 'updateOLDFormStart', @addOLDFormStart
      @listenTo @model, 'updateOLDFormEnd', @addOLDFormEnd
      @listenTo @model, 'updateOLDFormFail', @updateOLDFormFail
      @listenTo @model, 'updateOLDFormSuccess', @updateOLDFormSuccess

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

    propagateSubmitAttempted: ->
      for fieldView in @fieldViews()
        fieldView.submitAttempted = true

    modelAltered: ->
      for attr, val of @model.attributes
        originalValue = @originalModelCopy.get attr
        currentValue = @model.get attr
        if not _.isEqual originalValue, currentValue
          return true
      return false

    # TODO: will this one work?
    modelAltered_: ->
      not _.isEqual(@originalModelCopy.attributes, @model.attributes)

    submitForm: (event) ->
      if @modelAltered()
        @submitAttempted = true
        @propagateSubmitAttempted()
        @stopEvent event
        @setToModel()
        @disableForm()
        clientSideValidationErrors = @model.validate()
        if clientSideValidationErrors
          for attribute, error of clientSideValidationErrors
            @model.trigger "validationError:#{attribute}", error
          msg = 'See the error message(s) beneath the input fields.'
          Backbone.trigger "#{@addUpdateType}OLDFormFail", msg, @model
          @enableForm()
        else
          if @addUpdateType is 'add'
            @model.collection.addOLDForm @model
          else
            @model.collection.updateOLDForm @model
      else
        Backbone.trigger("#{@addUpdateType}OLDFormFail",
          'Please make some changes before attempting to save.')

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '-15%'
      options.color = @constructor.jQueryUIColors().errCo
      options

    spin: -> @$('.spinner-container').spin @spinnerOptions()

    stopSpin: -> @$('.spinner-container').spin false

    # Disable form input fields and submit button
    disableForm: ->
      @$('button.add-form-button').button 'disable'
      @disableFieldViews()

    disableFieldViews: ->
      for fieldView in @fieldViews()
        fieldView.disable()

    # Enable form input fields and submit button
    enableForm: ->
      @$('button.add-form-button').button 'enable'
      @enableFieldViews()

    enableFieldViews: ->
      for fieldView in @fieldViews()
        fieldView.enable()

    addOLDFormStart: -> @spin()

    addOLDFormEnd: ->
      @enableForm()
      @stopSpin()

    addOLDFormFail: (error) ->
      # The field views are listening for specific `validationError` events on
      # the form model. They will handle their own validation stuff.
      Backbone.trigger 'addOLDFormFail', error

    updateOLDFormFail: (error, formModel) ->
      console.log 'in updateOLDFormFail of FormAddWidget with ...'
      console.log error
      console.log formModel
      Backbone.trigger 'updateOLDFormFail', error, formModel

    updateOLDFormSuccess: (formModel) ->
      @originalModelCopy = @copyModel @model
      Backbone.trigger 'updateOLDFormSuccess', formModel

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
        'helpDialog:openTo',
        searchTerm: searchTerm
        scrollToIndex: 1
      )

    # <Enter> on a closed form opens it, <Esc> on an open form closes it.
    keydown: (event) ->
      switch event.which
        when 27
          @stopEvent event
          @hideSelf()

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
        utterance:                     UtteranceJudgementFieldView
        comments:                      CommentsFieldView
      OLD:
        narrow_phonetic_transcription: TextareaFieldView255
        phonetic_transcription:        TextareaFieldView255
        transcription:                 TranscriptionGrammaticalityFieldView255
        morpheme_break:                TextareaFieldView255
        morpheme_gloss:                TextareaFieldView255
        syntax:                        TextareaFieldView1023
        semantics:                     TextareaFieldView1023
        translations:                  TranslationsFieldView
        elicitation_method:            RelationalSelectFieldView
        syntactic_category:            RelationalSelectFieldView
        speaker:                       PersonSelectFieldView
        elicitor:                      UserSelectFieldView
        verifier:                      UserSelectFieldView
        source:                        SourceSelectFieldView
        status:                        RequiredSelectFieldView
        date_elicited:                 DateFieldView
        tags:                          MultiselectFieldView

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
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

    # Make the buttons into jQuery buttons.
    buttonify: ->
      @$('.dative-widget-header button').button()
      @$('.button-only-fieldset button').button()

      # Make all of righthand-side buttons into jQuery buttons and set the
      # position of their tooltips programmatically based on their
      # position/index.
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

    # Make the `title` attributes of the inputs/controls into jQueryUI tooltips.
    tooltipify: ->
      @$('.dative-widget-header .hide-form-add-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-widget-header .toggle-secondary-data-fields.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-70')
      @$('button.add-form-button')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('ul.button-only-fieldset button.toggle-secondary-data-fields')
        .tooltip position: @tooltipPositionLeft('-90')

    # Reset the model to its default state.
    clear: ->
      @model.set @getEmptyModelObject()
      @refresh()

    # Undo the (unsaved!) changes to the form (made presumably via the update
    # interface): restore the model to its pre-modified state.
    undoChanges: ->
      for attr, val of @originalModelCopy.attributes
        @model.set attr, @originalModelCopy.get(attr)
      @refresh()
      @setToModel()
      @originalModelCopy = @copyModel @model
      @validate()
      # FormView listens for the following and calls `indicateModelState`.
      @trigger 'forceModelChanged'

    validate: ->
      errors = @model.validate()
      for fieldView in @fieldViews()
        fieldView.validate errors

    # Tell all field views to refresh themselves to match the current state of
    # the model.
    refresh: ->
      for fieldView in @fieldViews()
        fieldView.refresh @model

    # Return a JS object representing an empty form model: note that this
    # crucially "empties" the editable attributes; that is, a form's id, its
    # enterer, etc., will not be represented in the returned model object.
    getEmptyModelObject: ->
      modelDefaults = @model.defaults()
      secondaryAttributes = @getEditableSecondaryAttributes()
      igtAttributes = @getFormAttributes @activeServerType, 'igt'
      translationAttributes = @getFormAttributes @activeServerType, 'translation'
      emptyModelObject = {}
      for attribute in secondaryAttributes.concat translationAttributes, igtAttributes
        emptyModelObject[attribute] = modelDefaults[attribute]
      emptyModelObject

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

