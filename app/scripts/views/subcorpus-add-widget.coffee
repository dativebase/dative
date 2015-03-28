define [
  './base'
  './textarea-field'
  './relational-select-field'
  './multiselect-field'
  './../models/subcorpus'
  './../collections/subcorpora'
  './../utils/globals'
  './../templates/subcorpus-add-widget'
], (BaseView, TextareaFieldView, RelationalSelectFieldView,
  MultiselectFieldView, SubcorpusModel, SubcorporaCollection, globals,
  subcorpusAddTemplate) ->

  # Subcorpus Add Widget View
  # -------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # subcorpus and updating an existing one.

  ##############################################################################
  # Field sub-classes with max lengths
  ##############################################################################

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options

  ##############################################################################
  # Subcorpus Add Widget
  ##############################################################################

  class SubcorpusAddWidgetView extends BaseView

    template: subcorpusAddTemplate
    className: 'add-subcorpus-widget dative-widget-center dative-shadowed-widget
      ui-widget ui-widget-content ui-corner-all'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @secondaryDataVisible = false
      @listenToEvents()
      @addUpdateType = options.addUpdateType or 'add'
      @submitAttempted = false

      # TODO: if this is an "add"-type form, then the original model copy
      # should (maybe) be an empty subcorpus.
      @originalModelCopy = @copyModel @model

    copyModel: (inputModel) ->
      newModel = new SubcorpusModel()
      for attr, val of @model.attributes
        newModel.set attr, inputModel.get(attr)
      newModel

    render: ->
      if @activeServerTypeIsOLD() and not @weHaveNewSubcorpusData()
        @model.getNewSubcorpusData() # Success in this request will call `@render()`
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
      'click button.add-subcorpus-button':         'submitForm'
      'click button.hide-subcorpus-add-widget':    'hideSelf'
      'click button.toggle-secondary-data-fields': 'toggleSecondaryDataAnimate'
      'click button.subcorpus-add-help':           'openSubcorpusAddHelp'
      'click button.clear-form':                   'clear'
      'click button.undo-changes':                 'undoChanges'
      'keydown':                                   'keydown'

    listenToEvents: ->
      super
      # Events specific to an OLD backend and the request for the data needed to create a subcorpus.
      @listenTo Backbone, 'getNewSubcorpusDataStart', @getNewSubcorpusDataStart
      @listenTo Backbone, 'getNewSubcorpusDataEnd', @getNewSubcorpusDataEnd
      @listenTo Backbone, 'getNewSubcorpusDataSuccess', @getNewSubcorpusDataSuccess
      @listenTo Backbone, 'getNewSubcorpusDataFail', @getNewSubcorpusDataFail

      @listenTo @model, 'addSubcorpusStart', @addSubcorpusStart
      @listenTo @model, 'addSubcorpusEnd', @addSubcorpusEnd
      @listenTo @model, 'addSubcorpusFail', @addSubcorpusFail

      @listenTo @model, 'updateSubcorpusStart', @addSubcorpusStart
      @listenTo @model, 'updateSubcorpusEnd', @addSubcorpusEnd
      @listenTo @model, 'updateSubcorpusFail', @updateSubcorpusFail
      @listenTo @model, 'updateSubcorpusSuccess', @updateSubcorpusSuccess

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
        'Add a Subcorpus'
      else
        'Update this subcorpus'

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
          Backbone.trigger "#{@addUpdateType}SubcorpusFail", msg, @model
          @enableForm()
        else
          if @addUpdateType is 'add'
            @model.collection.addSubcorpus @model
          else
            @model.collection.updateSubcorpus @model
      else
        Backbone.trigger("#{@addUpdateType}SubcorpusFail",
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
      @$('button.add-subcorpus-button').button 'disable'
      @disableFieldViews()

    disableFieldViews: ->
      for fieldView in @fieldViews()
        fieldView.disable()

    # Enable form input fields and submit button
    enableForm: ->
      @$('button.add-subcorpus-button').button 'enable'
      @enableFieldViews()

    enableFieldViews: ->
      for fieldView in @fieldViews()
        fieldView.enable()

    addSubcorpusStart: -> @spin()

    addSubcorpusEnd: ->
      @enableForm()
      @stopSpin()

    addSubcorpusFail: (error) ->
      # The field views are listening for specific `validationError` events on
      # the subcorpus model. They will handle their own validation stuff.
      Backbone.trigger 'addSubcorpusFail', error

    updateSubcorpusFail: (error, subcorpusModel) ->
      Backbone.trigger 'updateSubcorpusFail', error, subcorpusModel

    updateSubcorpusSuccess: (subcorpusModel) ->
      @originalModelCopy = @copyModel @model
      Backbone.trigger 'updateSubcorpusSuccess', subcorpusModel

    # Set the state of the "add a subcorpus" HTML form on the Dative subcorpus
    # model.
    setToModel: -> fv.setToModel() for fv in @fieldViews()

    # Focus the previous field. This is a hack that is required because the
    # multiSelect does not correctly move the focus on a Shift+Tab event.
    focusPreviousField: ->
      $focusedElement = @$ ':focus'
      inputSelector = 'textarea, .ms-list, .ui-selectmenu-button, button'
      $focusedElement
        .closest('li.dative-form-field')
        .prev()
          .find(inputSelector).first().focus()

    # Tell the Help dialog to open itself and search for "adding a subcorpus" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openSubcorpusAddHelp: ->
      if @addUpdateType is 'add'
        searchTerm = 'adding a subcorpus'
      else
        searchTerm = 'updating a subcorpus'
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: searchTerm
        scrollToIndex: 1
      )

    # <Enter> on a closed subcorpus opens it, <Esc> on an open subcorpus closes
    # it.
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
      name:        TextareaFieldView255
      tags:        MultiselectFieldView
      form_search: RelationalSelectFieldView

    # Return the appropriate FieldView (subclass) instance for a given
    # attribute, as specified in `@attribute2fieldView`. The default field view
    # is `TextareaFieldView`.
    getFieldView: (attribute) ->
      params = # All `FieldView` subclasses expect `attribute` and `model` on init
        resource: 'subcorpora'
        attribute: attribute # e.g., "name"
        model: @model
        options: @getOptions() # These are the OLD <select> options relevant to OLD corpora, cf. GET requests to corpora/new
      if attribute of @attribute2fieldView
        MyFieldView = @attribute2fieldView[attribute]
        new MyFieldView params
      else # the default field view is a(n expandable) textarea.
        new TextareaFieldView params

    # Put the appropriate FieldView instances in `@primaryFieldViews` and.
    # `@secondaryFieldViews`
    getFieldViews: ->
      @getPrimaryFieldViews()
      @getSecondaryFieldViews()

    primaryAttributes: [
      'name'
      'description'
    ]

    editableSecondaryAttributes: [
      'content'
      'tags'
      'form_search'
    ]

    # Put the appropriate FieldView instances in `@primaryFieldViews`.
    getPrimaryFieldViews: ->
      @primaryFieldViews = []
      for attribute in @primaryAttributes
        @primaryFieldViews.push @getFieldView attribute

    # Put the appropriate FieldView instances in `@secondaryFieldViews`.
    getSecondaryFieldViews: ->
      @secondaryFieldViews = []
      for attribute in @editableSecondaryAttributes
        @secondaryFieldViews.push @getFieldView attribute

    fieldViews: ->
      try
        @primaryFieldViews.concat @secondaryFieldViews
      catch
        []

    renderFieldViews: ->
      @renderPrimaryFieldViews()
      @renderSecondaryFieldViews()

    renderPrimaryFieldViews: ->
      $primaryDataUL = @$ @primaryDataSelector
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

    # Returns true of `globals` has a key for `subcorpusData`. The value of
    # this key is an object containing a subset of the following keys:
    # `form_searches`, `users`, `tags`, and `corpus_formats`.
    weHaveNewSubcorpusData: -> globals.subcorpusData?

    # Return an object representing the options for forced-choice inputs.
    # Currently only relevant for the OLD.
    getOptions: ->
      if globals.subcorpusData
        globals.subcorpusData
      else
        {}

    getNewSubcorpusDataStart: -> @spin()

    getNewSubcorpusDataEnd: -> @stopSpin()

    getNewSubcorpusDataSuccess: (data) ->
      globals.subcorpusData = data
      @render()

    getNewSubcorpusDataFail: ->
      console.log 'Failed to retrieve the data from the OLD server which is
        necessary for creating a new subcorpus'


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
      @$('.dative-widget-header .hide-subcorpus-add-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-widget-header .toggle-secondary-data-fields.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-70')
      @$('button.add-subcorpus-button')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('ul.button-only-fieldset button.toggle-secondary-data-fields')
        .tooltip position: @tooltipPositionLeft('-90')

    # Reset the model to its default state.
    clear: ->
      @model.set @getEmptyModelObject()
      @refresh()

    # Undo the (unsaved!) changes to the subcorpus (made presumably via the update
    # interface): restore the model to its pre-modified state.
    undoChanges: ->
      for attr, val of @originalModelCopy.attributes
        @model.set attr, @originalModelCopy.get(attr)
      @refresh()
      @setToModel()
      @originalModelCopy = @copyModel @model
      @validate()
      # SubcorpusView listens for the following and calls `indicateModelState`.
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

    # Return a JS object representing an empty subcorpus model: note that this
    # crucially "empties" the editable attributes; that is, a subcorpus's id,
    # its enterer, etc., will not be represented in the returned model object.
    getEmptyModelObject: ->
      modelDefaults = @model.defaults()
      emptyModelObject = {}
      for attribute in @editableSecondaryAttributes.concat @primaryAttributes
        emptyModelObject[attribute] = modelDefaults[attribute]
      emptyModelObject

    ############################################################################
    # Showing, hiding and toggling
    ############################################################################

    # The SubcorporaView will handle this hiding.
    hideSelf: -> @trigger 'subcorpusAddView:hide'

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

    # Make the "toggle secondary data" button have the appropriate icon and
    # tooltip.
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

