define [
  'backbone'
  './form-handler-base'
  './textarea-field'
  './select-field'
  './required-select-field'
  './person-select-field'
  './user-select-field'
  './source-select-field'
  './transcription-grammaticality-field'
  './translations-field'
  './../models/form'
  './../utils/globals'
  './../templates/form-add-widget'
  'multiselect'
  'jqueryelastic'
], (Backbone, FormHandlerBaseView, TextareaFieldView, SelectFieldView,
  RequiredSelectFieldView, PersonSelectFieldView, UserSelectFieldView,
  SourceSelectFieldView, TranscriptionGrammaticalityFieldView,
  TranslationsFieldView, FormModel, globals, formAddTemplate) ->

  # Form Add Widget View
  # --------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # form and updating an existing one. Currently this view is being
  # used as a sub-view of the "forms browse" page view.
  #
  # (Note: the page-view-level `FormAddView` is currently not being used and
  # may be removed entirely.)

  class FormAddWidgetView extends FormHandlerBaseView

    template: formAddTemplate

    initialize: ->
      @activeServerType = @getActiveServerType()
      @secondaryDataVisible = false
      @wideSelectMenuWidth = 548
      @listenToEvents()
      @setDatumFieldsArray()

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

    # Return the appropriate FieldView instance for a given attribute.
    # Default field view is `FieldView`.
    getFieldView: (attribute) =>
      params =
        attribute: attribute
        model: @model
        options: @getOptions()
      if attribute of @attribute2fieldView[@activeServerType]
        MyFieldView = @attribute2fieldView[@activeServerType][attribute]
        new MyFieldView params
      else # the default field view is a(n expandable) textarea.
        new TextareaFieldView params

    # Maps attributes to their appropriate FieldView classes.
    #utterance:          'UtteranceJudgementView'
    #comments:           'CommentsView' # direct Datum attribute
    attribute2fieldView:
      FieldDB:{}
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

    events:
      'change': 'setToModel' # fires when multi-select changes
      'input': 'setToModel' # fires when an input, textarea or date-picker changes
      'selectmenuchange': 'setToModel' # fires when a selectmenu changes
      'menuselect': 'setToModel' # fires when the tags multi-select changes (not working?...)
      'keydown form.formAdd': 'keyboardEvents'
      'click button.add-form-button': 'submitForm'
      'click button.hide-form-add-widget': 'hideSelf'
      'click button.toggle-secondary-data': 'toggleSecondaryDataAnimate'
      'click .form-add-help': 'openFormAddHelp'

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()

      # Events specific to an OLD backend and the request for the data needed to create a form.
      @listenTo Backbone, 'getOLDNewFormDataStart', @getOLDNewFormDataStart
      @listenTo Backbone, 'getOLDNewFormDataEnd', @getOLDNewFormDataEnd
      @listenTo Backbone, 'getOLDNewFormDataSuccess', @getOLDNewFormDataSuccess
      @listenTo Backbone, 'getOLDNewFormDataFail', @getOLDNewFormDataFail


    # Tell the Help dialog to open itself and search for "browsing forms" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want
    openFormAddHelp: ->
      Backbone.trigger(
        'helpDialog:toggle',
        searchTerm: 'adding a form'
        scrollToIndex: 1
      )

    render: ->
      if @activeServerTypeIsOLD() and not @weHaveOLDNewFormData()
        @model.getOLDNewFormData()
        return
      @getFieldViews()
      @html()
      @secondaryDataVisibility()
      @renderFieldViews()
      @guify()
      @fixRoundedBorders() # defined in BaseView
      @listenToEvents()
      @

    # TODO: AJAX/CORS-fetch the form add metadata (OLD-depending?), if needed
    # and spin() in the meantime ...
    render_: (taskId) ->
      @html()
      @secondaryDataVisibility()
      @renderFieldViews()
      @guify()
      @fixRoundedBorders() # defined in BaseView
      @listenToEvents()
      if @activeServerTypeIsOLD() and not @weHaveOLDNewFormData()
        @model.getOLDNewFormData()
      @

    primaryDataSelector: 'ul.primary-data'
    secondaryDataSelector: 'ul.secondary-data'

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

    getActiveServerType: ->
      try
        globals.applicationSettings.get('activeServer').get 'type'
      catch
        null

    activeServerTypeIsOLD: ->
      @getActiveServerType() is 'OLD'

    # Returns true of `globals` has a key for `oldData`. The value of this key is
    # an object containing speakers, users, grammaticalities, tags, etc.
    weHaveOLDNewFormData: ->
      globals.oldData?

    # These arrays are used to categorize FieldDB's `datumFields` objects by their
    # keys.
    # TODO: at least some of this should be in application settings (and saved
    # to server...)
    # TODO: deprecate this.
    setDatumFieldsArray: ->
      @primaryDatumFields = [
        'judgement'
        'utterance'
        'morphemes'
        'gloss'
        'translation'
      ]
      @secondaryDatumFields = [
        'tags'
        'validationStatus'
        'syntacticCategory'
        'syntacticTreeLatex'
      ]
      @autopopulatedDatumFields = [
        'modifiedByUser'
        'enteredByUser'
      ]

    # Return the primary datum fields, sorted according to the label order given
    # in `@primaryDatumFields`.
    getPrimaryDatumFields: (datumFields) =>
      primaryFields = (field for field in datumFields \
        when field.label in @primaryDatumFields)
      _.sortBy(
        primaryFields
        (field) => @primaryDatumFields.indexOf(field.label))

    fieldDBGenericInputGenerator: (attribute, context, inputCallback) =>
      "#{@getFieldDBInputLabel attribute, context}
       #{inputCallback attribute, context}"

    getFieldDBInputLabel: (attribute, context) =>
      "<label for='#{@utils.camel2hyphen attribute}'
        >#{@utils.camel2regular attribute}</label>"

    # Textarea input generator; the default input for FieldDB fields.
    fieldDBTextareaInputGenerator: (attribute, context) =>
      inputCallback = (attribute, context) =>
        tooltip = @getFieldDBAttributeTooltip attribute
        value = @model.getDatumValueSmart attribute
        "<textarea rows='1' name='#{@utils.camel2hyphen attribute}'
          class='#{@utils.camel2hyphen attribute} ui-corner-all form-add-input dative-tooltip'
          title='#{tooltip}'
          >#{value}</textarea>"
      @fieldDBGenericInputGenerator attribute, context, inputCallback

    # Textarea input generator; the default input for FieldDB fields.
    fieldDBTranslationInputGenerator: (attribute, context) =>
      inputCallback = (attribute, context) =>
        tooltip = @getFieldDBAttributeTooltip attribute
        value = @model.getDatumValueSmart attribute
        "<textarea rows='1' name='#{@utils.camel2hyphen attribute}'
          class='#{@utils.camel2hyphen attribute} singular-translation
            ui-corner-all form-add-input dative-tooltip'
          title='#{tooltip}'
          >#{value}</textarea>"
      @fieldDBGenericInputGenerator attribute, context, inputCallback

    # Judgement Input & Utterance Textarea.
    fieldDBUtteranceJudgementInputGenerator: (attribute, context) =>
      inputCallback = (attribute, context) =>
        "#{@fieldDBJudgementInputGenerator context}
         #{@fieldDBUtteranceInputGenerator attribute, context}"
      @fieldDBGenericInputGenerator attribute, context, inputCallback

    # Utterance Textarea. TODO: make this different from
    # fieldDBTextareaInputGenerator in terms of a class that reduces the
    # textarea's width.
    fieldDBUtteranceInputGenerator: (attribute, context) =>
      tooltip = @getFieldDBAttributeTooltip attribute
      value = @model.getDatumValueSmart attribute
      "<textarea rows='1' name='#{@utils.camel2hyphen attribute}'
        class='#{@utils.camel2hyphen attribute} ui-corner-all form-add-input dative-tooltip'
        title='#{tooltip}'
        >#{value}</textarea>"

    # Judgement Input.
    fieldDBJudgementInputGenerator: (context) =>
      value = @model.getDatumValueSmart 'judgement'
      tooltip = @getFieldDBAttributeTooltip 'judgement'
      "<input name='judgement'
        type='text'
        class='judgement ui-corner-all dative-tooltip form-add-input'
        title='#{tooltip}'
        value='#{value}' />"

    fieldDBCommentsInputGenerator: (attribute, context) =>
      inputCallback = (attribute, context) =>
        # context[attribute]
        'fieldDB comments go here'
      @fieldDBGenericInputGenerator attribute, context, inputCallback

    getSecondaryDatumFields: (datumFields) =>
      secondaryFields = (field for field in datumFields \
        when field.label not in @primaryDatumFields.concat @autopopulatedDatumFields)
      _.sortBy(
        secondaryFields
        (field) => @secondaryDatumFields.indexOf(field.label))

    # Write the initial HTML to the page.
    html: ->
      context = _.extend(@model.toJSON(), {
        headerTitle: 'Add a Form'
        options: @getOptions()
        activeServerType: @getActiveServerType()
        h: # "h" for "helpers"
          fieldDB:
            inputGenerator: @getFieldDBFormAttributeInputGenerator
            igtAttributes: @getFieldDBFormAttributes 'igt'
            translationAttributes: @getFieldDBFormAttributes 'translation'
            secondaryAttributes: @getEditableSecondaryAttributes()
      })
      @$el.html @template(context)

    # Return an object representing the options for forced-choice inputs.
    # Currently only relevant for the OLD.
    getOptions: ->
      if globals.oldData
        @addOLDStatuses globals.oldData
      else
        {}

    addOLDStatuses: (options) ->
      options.statuses = []
      for status in ['tested', 'requires testing']
        options.statuses.push id: status, name: status
      options

    # Return a crucially ordered array of editable secondary data attributes.
    getEditableSecondaryAttributes: ->
      switch @activeServerType
        when 'FieldDB' then @getFieldDBEditableSecondaryAttributes()
        when 'OLD' then @getOLDEditableSecondaryAttributes()

    # Return a crucially ordered array of editable form attributes.
    # A form attribute is editable and secondary iff:
    # - it is secondary, as specified in the app settings model AND
    # - it is not read-only (see app settings model)
    getOLDEditableSecondaryAttributes: ->
      secondaryAttributes = @getFormAttributes @activeServerType, 'secondary'
      readonlyAttributes = @getFormAttributes @activeServerType, 'readonly'
      (a for a in secondaryAttributes when a not in readonlyAttributes)

    # Return a crucially ordered array of editable datum attributes (where an
    # attribute may be just that or it may be the `label` value of a
    # session/datum field). A datum attribute is editable and secondary iff:
    # - it is a datum field or it is `datum.comments` AND
    # - it is not read-only (see app settings model) AND
    # - it is not "primary" (i.e., IGT, translation or grammaticality, as defined in app settings)
    getFieldDBEditableSecondaryAttributes: ->

      # Get the list of *possible* editable secondary attributes: datumField
      # labels and `comments`
      datumFieldLabels = (field.label for field in @model.get('datumFields'))
      possibleEditableSecondaryAttributes = datumFieldLabels.concat ['comments']

      # `secondaryAttributes` is the ordered list of datum attributes that are
      # specified as "secondary" in the applicationSettings model.
      orderedSecondaryAttributes = @getFieldDBFormAttributes 'secondary'
      orderedEditableSecondaryAttributes = (a for a in \
        orderedSecondaryAttributes when a in \
        possibleEditableSecondaryAttributes)

      # These attributes can NOT be editable secondary attributes.
      # (Note: these arrays are all defined in the application settings model.)
      unavailableAttributes = [].concat(
        @getFieldDBFormAttributes 'readonly'
        @getFieldDBFormAttributes 'igt'
        @getFieldDBFormAttributes 'grammaticality'
        @getFieldDBFormAttributes 'translation'
      )

      otherSecondaryAttributes = (a for a in \
        possibleEditableSecondaryAttributes when a not in \
        orderedEditableSecondaryAttributes)

      secondaryAttributes = orderedEditableSecondaryAttributes
        .concat otherSecondaryAttributes

      (a for a in secondaryAttributes when a not in unavailableAttributes)

    # Return an "input generator" (a method that generates data input HTML,
    # e.g., an input[type=text]) for a FieldDB form attribute.
    getFieldDBFormAttributeInputGenerator: (attribute) =>
      if attribute of @fieldDBFormAttribute2InputGenerator
        @[@fieldDBFormAttribute2InputGenerator[attribute]]
      else
        @fieldDBTextareaInputGenerator

    # Map FieldDB form attributes to input generator method names.
    fieldDBFormAttribute2InputGenerator:
      'utterance':          'fieldDBUtteranceJudgementInputGenerator'
      'comments':           'fieldDBCommentsInputGenerator' # direct Datum attribute
      'translation':        'fieldDBTranslationInputGenerator'

    ############################################################################
    # jQuery (UI) GUI stuff.
    ############################################################################

    # Make the vanilla HTML nice and jQueryUI-ified.
    # TODO: a lot of the method calls in here should be removed/modified because
    # the field/input subviews should take care of this themselves.
    guify: ->
      #@selectmenuify()
      @multiSelectify()
      @buttonify()
      @datepickerify()
      @bordercolorify()
      #@elasticize() # NOTE: this should be done in the individual FieldViews, but that's not working for some reason.
      @tooltipify()

    # Make the <select>s into nice jQuery selectmenus.
    selectmenuify: ->
      @$('select')
        .filter('.grammaticality')
          .selectmenu width: @grammaticalitySelectMenuWidth
          .each (index, element) =>
            @transferClassAndTitle @$(element)
          .end()
        .not('.grammaticality, .tags')
          .selectmenu width: @wideSelectMenuWidth
          .each (index, element) =>
            @transferClassAndTitle @$(element)

    # Make the tags <select> into a jQuery multiSelect
    multiSelectify: ->
      @$('select[name=tags]')
        .multiSelect()
        .each (index, element) =>
          @transferClassAndTitle @$(element), '.ms-container'

    # Make the buttons into nice jQuery buttons.
    buttonify: ->
      @$('.dative-widget-header button').button()
      @$('.button-only-fieldset button').button()

    # Make the date elicited input into a nice jQuery datepickter.
    datepickerify: ->
      @$('input[name="dateElicited"]').datepicker
        appendText: "<span style='margin: 0 10px;'>mm/dd/yyyy</span>"
        autoSize: true

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('select, input, textarea')
        .css "border-color", @constructor.jQueryUIColors().defBo

    # Use jQuery elastic to make <textarea>s stretch to fit their content.
    elasticize: ->
      @$('textarea')
        .elastic compactOnBlur: false
        .css height: '16px' # Do this, otherwise jquery-elastic erratically increases textarea height ...

    # Make the `title` attributes of the inputs/controls into tooltips
    # The jQuery chain is simply to get the tooltip positioning right.
    tooltipify: ->
      @$('.dative-widget-header')
        .find('.hide-form-add-widget.dative-tooltip')
          .tooltip
            position: @tooltipPositionLeft '-20'
          .end()
        .find('.toggle-secondary-data.dative-tooltip')
          .tooltip
            position: @tooltipPositionLeft '-70'
          .end()
        .find('.form-add-help.dative-tooltip')
          .tooltip
            position: @tooltipPositionRight '+20'
          .end()
      @$('button.add-form-button')
        .tooltip
          position: @tooltipPositionLeft '-20'


    ############################################################################
    # Logic for populating the model.
    ############################################################################

    # Set the state of the "add a form" HTML form on the Dative form model.
    setToModel: ->
      modelObject = @getModelObjectFromAddForm()
      # @setFieldDBDatum modelObject
      # @log _.keys(modelObject).sort()
      # @log _.keys(@model.toJSON()).sort()
      @model?.set modelObject

    # Create a FieldDB datum model.
    # NOTE: this method is currently not being used
    setFieldDBDatum: (modelObject) ->
      tobesaved = new FieldDB.Document modelObject
      tobesaved.dbname = tobesaved.application.currentFieldDB.dbname
      tobesaved.url = "#{tobesaved.application.currentFieldDB.url}/#{tobesaved.dbname}"
      tobesaved.save()

    # Extract data in the inputs of the HTML "Add a Form" form and
    # convert them to an object
    getModelObjectFromAddForm: ->
      modelObject = {}
      for {name, value} in @getFields()
        modelObject = @createModelObjectFirstPass modelObject, name, value
      modelObject = @createModelObjectSecondPass modelObject
      # The tags multi-select value needs to be explicitly extracted
      modelObject.tags = $('div.form-add-form select[name=tags]').val()
      modelObject

    # Get an array of objects with `name` and `value` attributes: extracted
    # from the HTML fields in the widget.
    getFields: ->
      @$('div.form-add-form :input').serializeArray()

    # Return the passed-in `modelObject` where it's object-type values
    # (created by `createModelObjectFirstPass`) are converted to arrays,
    # that is
    #     modelObject['translations'] = {1: {grammaticality: '*', transcription: 'dog'}, ...}}
    # becomes
    #     modelObject['translations'] = [{grammaticality: '*', transcription: 'dog'}, ...]
    createModelObjectSecondPass: (modelObject) ->
      for attr, value of modelObject
        if @utils.type(value) is 'object'
          array = []
          for key of (k for k of value).sort()
            array.push value[key]
          modelObject[attr] = array
      modelObject

    # Return the passed-in `modelObject` with the passed-in `name` and
    # `value`.
    # The challenge here is to take form fields with names like
    # 'translations-1.grammaticality' and 'translations-1.transcription' and
    # use them to produce attributes of `modelObject` that are lists of objects,
    # as in:
    #     modelObject['translations'] = [{grammaticality: '*', transcription: 'dog'}, ...]
    # This function is the first pass in this task: it returns an object with
    # indices as keys:
    #     modelObject['translations'] = {1: {grammaticality: '*', transcription: 'dog'}, ...}}
    createModelObjectFirstPass: (modelObject, name, value) ->
      if name.split('-').length is 2
        [attr, tmp] = name.split '-'
        [index, subAttr] = tmp.split '.'
        if attr of modelObject
          attrVal = modelObject[attr]
        else
          attrVal = modelObject[attr] = {}
        if index of attrVal
          tmp = attrVal[index]
        else
          tmp = attrVal[index] = {}
        tmp[subAttr] = value
      else # This is the regular case: just a regular name/value pair
        modelObject[name] = value
      modelObject


    ############################################################################
    # Showing, hiding and toggling
    ############################################################################

    # The FormsView will handle this hiding.
    hideSelf: ->
      @trigger 'formAddView:hide'

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
      @$(@secondaryDataSelector).slideDown()

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
        @$('button.toggle-secondary-data')
          .tooltip
            content: 'hide the secondary data input fields'
          .find('i').first()
            .removeClass 'fa-angle-down'
            .addClass 'fa-angle-up'
      else
        @$('button.toggle-secondary-data')
          .tooltip
            content: 'show the secondary data input fields'
          .find('i').first()
            .removeClass 'fa-angle-up'
            .addClass 'fa-angle-down'



    # Add the data from the associated model to the <select>s, i.e. preserve
    # state across views. (Note that the values of textareas and text inputs
    # are inserted via the templating system.)
    addModel: (context) ->

      # grammaticality selectmenus for translations >= 1
      for translation, index in @model.get('translations')
        if index > 0
          $('button.insertTranslationFieldButton', context).click()
        $("select[name='translations-#{index}.grammaticality']")
          .val(translation.grammaticality)
          .selectmenu 'refresh', true
        $("textarea[name='translations-#{index}.transcription']")
          .val(translation.transcription)

      # other selectmenus
      for attrName in ['grammaticality', 'elicitationMethod',
        'syntacticCategory', 'speaker', 'elicitor', 'verifier', 'source']
        if @model.get(attrName)
          $("select[name=#{attrName}]", context)
            .val(@model.get(attrName))
            .selectmenu 'refresh', true

      # tags multiSelect (see http://loudev.com/)
      if @model.get('tags')
        $('select[name="tags"]', context)
          .multiSelect 'select', @model.get('tags')


    # Handle special keydown events in the HTML form.
    # - <Ctrl+Return> in a textarea submits the form
    # - <Return> in an input submits the form
    # - <Shift+Tab> in the tags multiselect focuses the previous input
    keyboardEvents: (event) ->
      if event.which is 13
        targetTagName = $(event.target).prop 'tagName'
        if event.ctrlKey and targetTagName is 'TEXTAREA'
          @stopEvent event
          @$('.add-form-button').click()
        else if targetTagName is 'INPUT'
          @stopEvent event
          @$('.add-form-button').click()
      # TODO: this is supposed to make Shift+Tab focus the elicitationMethod
      # multiselect, but instead it's focusing the speaker comments. I haven't
      # yet been able to figure out why.
      else if event.shiftKey and event.which is 9 and
      $(event.target).parents('div.tags-multiselect').length > 0
        @$('.ui-selectmenu-button').filter('.elicitation-method').eq(0).focus()

    submitForm: (event) ->
      @stopEvent event
      console.log 'you want to submit this form'


    # TODO: don't delete this method yet. It may be useful for populating
    # the widget's inputs for form updating.
    # Insert options into the select fields in the "Add a Form" form.
    populateSelectFields: (context) ->

      # TODO: create an abstraction to hold secondary and meta-data,
      # i.e., an interface that returns users, speakers, elicitation methods, etc.
      # The API exposed should gracefully handle complications like client-side caching
      # with asynchronous RESTful sync and initial RESTful requests.
      #$.get('form/get_form_options_ajax', null, updateAddInterface, 'json');

      formAddOptions = @fakeFormAddOptions
      updateAddInterface = (formAddOptions, statusText) =>
        if statusText is 'success'
          # Save the formAddOptions for later,
          #  e.g., for additional translation grammaticality select fields
          @formAddOptions = formAddOptions

          # Make all of the textareas elastic
          @$('textarea').elastic compactOnBlur: false

          # Populate grammaticality
          $selectGrammaticality = @$('select.grammaticality')
          for grammaticality in formAddOptions.grammaticalities
            $selectGrammaticality
              .append($('<option>')
                .attr('value', grammaticality)
                .text(grammaticality))
          $selectGrammaticality.selectmenu width: @grammaticalitySelectMenuWidth

          # Populate & GUI-ify elicitationMethod
          $selectElicitationMethod = @$('select[name=elicitationMethod]')
          for [elicitationMethodId, elicitationMethod] in formAddOptions.elicitationMethods
            $selectElicitationMethod
              .append($('<option>')
                .attr('value', elicitationMethodId)
                .text(elicitationMethod))
          $selectElicitationMethod.selectmenu()

          # Populate & GUI-ify tags
          tagsSelect = @$('select[name=tags]')
          for [tagId, tag] in formAddOptions.tags
            tagsSelect.append($('<option>')
              .attr('value', tagId)
              .text(tag))
          tagsSelect.multiSelect()

          # Populate category
          $syntacticCategorySelect = @$ 'select[name=syntacticCategory]'
          for [categoryId, category] in formAddOptions.categories
            $syntacticCategorySelect
              .append($('<option>')
                .attr('value', categoryId)
                .text(category))
          $syntacticCategorySelect.selectmenu()

          # Populate speaker
          $speakerSelect = @$ 'select[name=speaker]'
          for [speakerId, speaker] in formAddOptions.speakers
            $speakerSelect.append($('<option>')
              .attr('value', speakerId)
              .text(speaker))
          $speakerSelect.selectmenu()

          # Populate elicitor & verifier
          $elicitorSelect = @$ 'select[name=elicitor]'
          $verifierSelect = @$ 'select[name=verifier]'
          for [userId, user] in formAddOptions.users
            $elicitorSelect
              .append($('<option>')
                .attr('value', userId)
                .text(user))
            $verifierSelect
              .append($('<option>')
                .attr('value', userId)
                .text(user))
          $verifierSelect.selectmenu()
          $elicitorSelect.selectmenu()

          # Populate source
          $sourceSelect = @$ 'select[name=source]'
          for [sourceId, source] in formAddOptions.sources
            $sourceSelect
              .append($('<option>')
                .attr('value', sourceId)
                .text(source))
          $sourceSelect.selectmenu()

      updateAddInterface formAddOptions, 'success'


    ############################################################################
    # New translation field(s) logic
    ############################################################################

    # Append a new translation Field <li> at the bottom of the IGT data
    # section.
    appendTranslationField: (event) ->
      @stopEvent event
      nextIndex = @$('li.translation-li').length
      @$('ul.igt-data')
        .append @getTranslationLI(nextIndex)
        .find('li:last')
          .hide()
          .slideDown()
          .find('textarea').first().focus()
      @guifyLastTranslationField()

    # On a newly added translation field: create nice buttons, selectmenus,
    # borders, and tooltips.
    guifyLastTranslationField: ($li=null) ->
      $li = if $li then $li else @$('li.translation-li').last()
      @buttonifyLastTranslationField $li
      @selectmenuifyLastTranslationField $li
      @borderColorizeLastTranslationField $li
      @tooltipifyLastTranslationField $li

    # Make the <select> of the newly created translation field into a selectmenu.
    selectmenuifyLastTranslationField: ($li=null) ->
      $li = if $li then $li else @$('li.translation-li').last()
      $li.find('select.translation-grammaticality')
        .selectmenu(width: @grammaticalitySelectMenuWidth)
        .next('.ui-selectmenu-button')
          .addClass('translation-grammaticality')

    # Make the <button> of the newly created translation field into a jQuery button.
    buttonifyLastTranslationField: ($li=null) ->
      $li = if $li then $li else @$('li.translation-li').last()
      $li.find('button').button()

    # Make the border color of the newly created translation field match the jQueryUI theme.
    borderColorizeLastTranslationField: ($li=null) ->
      $li = if $li then $li else @$('li.translation-li').last()
      $li.find('textarea')
        .css 'border-color', @constructor.jQueryUIColors().defBo

    # Give jQuery tooltips to the elements of the newly created translation field.
    tooltipifyLastTranslationField: ($li=null) ->
      $li = if $li then $li else @$('li.translation-li').last()
      $li
        .find('button.dative-tooltip')
          .tooltip
            position: @tooltipPositionLeft '-630'
          .end()
        .find('textarea.dative-tooltip')
          .tooltip
            position: @tooltipPositionLeft '-170'
          .end()
        .find('.ui-selectmenu-button').filter('.translation-grammaticality')
          .tooltip
            items: 'span'
            content: 'The acceptibility of this as a translation for the form'
            position: @tooltipPositionLeft()

    # This is called when a user clicks on the "-" "remove-this-translation" button.
    removeTranslationField: (event) ->
      @stopEvent event
      $translationLI = $(event.target).closest('li')
      $translationLI.slideUp
        complete: ->
          $translationLI
            .prev()
            .find('button').focus()
          $translationLI.remove()

    # Return a <li> with the inputs and controls for creating a new translation.
    getTranslationLI: (index) ->
      "<li class=\"translation-li\">
        #{@getTranslationLabel index}
        #{@getTranslationSelect index}
        #{@getTranslationTextarea index}
        #{@getTranslationButton()}
      </li>"

    # Return a "remove-this-translation" <button> for a new translation.
    getTranslationButton: ->
      "<button class=\"remove-translation-field dative-tooltip
        append-remove-translation-field\"
        title=\"Delete this translation.\">
        <i class=\"fa fa-fw fa-minus\"></i>
      </button>"

    # Return a <label> for a new translation.
    getTranslationLabel: (index) ->
      "<label class=\"translation-label\"
        for=\"translations-#{index}.transcription\"
        >Translation</label>"

    # Return a <textarea> for a new translation.
    getTranslationTextarea: (index) ->
      "<textarea name=\"translations-#{index}.transcription\"
        maxlength=\"255\"
        class=\"translation translation-transcription ui-corner-all
          dative-tooltip\"
        title=\"The text of the translation\"
        ></textarea>"

    # Return a <select> element for grammaticality/acceptibility choices.
    getTranslationSelect: (index) ->
      "<select name=\"translations-#{index}.grammaticality\"
        class=\"grammaticality translation-grammaticality dative-tooltip\"
        title=\"The acceptibility of this as a translation for the form\">
        #{@getGrammaticalitySelectOptions()}
      </select>"

    # Return a set of <option> elements for grammaticality/acceptibility choices.
    getGrammaticalitySelectOptions: ->
      ("<option value=\"#{grammaticality}\">#{grammaticality}</option>" \
        for grammaticality in @fakeFormAddOptions.grammaticalities).join ''


    ############################################################################
    # Fake form add options.
    ############################################################################

    # TODO: AJAX-query these for the OLD (and FieldDB?)

    # Fake formAddOptions object for development purposes.
    fakeFormAddOptions:
      grammaticalities: [
        '',
        '*',
        '****',
        '?',
        '#'
      ]
      elicitationMethods: [
        [0, '']
        [1, 'volunteered']
        [2, 'translation']
      ]
      tags: [
        [0, 'imperfective']
        [1, 'habitual']
        [2, 'frog']
        [3, 'banana']
        [4, 'helicopter']
        [5, 'fish']
        [6, 'spoon']
        [7, 'politician']
        [8, 'freak']
        [9, 'dingo']
      ]
      categories: [
        [0, '']
        [1, 'N']
        [2, 'V']
      ]
      speakers: [
        [0, '']
        [1, 'Jeff Bridges']
        [2, 'Leonard Cohen']
      ]
      users: [
        [0, '']
        [1, 'Mac Daddy']
        [2, 'Paddy Wagon']
        [3, 'Abba Face']
        [4, 'Zacharia Murphy']
      ]
      sources: [
        [0, '']
        [1, 'Frantz (1995)']
        [2, 'Chomsky (1965)']
      ]

# TODO
#
# 1. set these here or have the servers do it?:
#   - datetimeEntered
#   - datetimeModified
#   - enterer
#   - modifier
#
# 2. have the form accommodate FieldDB's non-relational data structure:
#   - no selectmenus for elicitor, category, etc.
#   - tags is just a text field
#   - elicitor/verifier are strings
#   - perhaps have warning-based validation for these
#
# 3. fieldDBComments: an array of objects (I think)
#   - form fields diverge, depending on OLD/FieldDB backend
#
# 4. fieldDBDatumTags and fieldDBTags
#   - I am unsure what the data struture of these fields are, exactly
#
# 5. id and UUID:
#   - differences between OLD and FieldDB in this respect
#
# 6. modifiers (fieldDB only)
#   - an array of some sort.
#
# 7. breakGlossCategory, morphemeBreakIds, and morphemeGlossIds
#   - these are OLD-specific and are generated server-side, but
#     they are integral to the morpho-lexical consistency stuff.
#
# 8. Create Dative fields for narrowPhoneticTranscription, phoneticTranscription
#    and semantics.
#   - these are OLD-specific, but FieldDB can easily accommodate them.
#
# 9. Create Dative fields for status
#
# 10. Create Dative field for syntacticCategories
#   - user-specifiable
#   - the OLD creates this server-side using morphemeBreak and morphemeGloss and the 
#
# 11. syntacticTreeLaTeX and syntacticTreePTB
#


    ############################################################################
    # Responding to events from request to get data needed to create a new OLD form
    ############################################################################

    getOLDNewFormDataStart: ->
      @spin()

    getOLDNewFormDataEnd: ->
      @stopSpin()

    getOLDNewFormDataSuccess: (data) ->
      globals.oldData = data
      @render()

    getOLDNewFormDataFail: ->
      console.log 'Failed to retrieve the data from the OLD server which is
        necessary for creating a new form'

