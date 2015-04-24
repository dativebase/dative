define [
  './resource-add-widget'
  './textarea-field'
  './relational-select-field'
  './multiselect-field'
  './utterance-judgement-field'
  './comments-field'
  './transcription-grammaticality-field'
  './translations-field'
  './person-select-field'
  './user-select-field'
  './source-select-field'
  './required-select-field'
  './date-field'
  './../models/form'
  './../utils/globals'
], (ResourceAddWidgetView, TextareaFieldView, RelationalSelectFieldView,
  MultiselectFieldView, UtteranceJudgementFieldView, CommentsFieldView,
  TranscriptionGrammaticalityFieldView, TranslationsFieldView,
  PersonSelectFieldView, UserSelectFieldView, SourceSelectFieldView,
  RequiredSelectFieldView, DateFieldView, 
  FormModel, globals) ->

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


  # Form Add Widget View
  # --------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # form and updating an existing one.

  ##############################################################################
  # Form Add Widget
  ##############################################################################

  class FormAddWidgetView extends ResourceAddWidgetView

    resourceName: 'form'
    resourceModel: FormModel

    initialize: (options) ->
      super
      @setAttribute2fieldView()
      @setPrimaryAttributes()
      @setEditableSecondaryAttributes()

    setAttribute2fieldView: ->
      switch @activeServerType
        when 'FieldDB'
          @attribute2fieldView = @attribute2fieldViewFieldDB
        when 'OLD'
          @attribute2fieldView = @attribute2fieldViewOLD

    setPrimaryAttributes: ->
      igtAttributes = @getFormAttributes @activeServerType, 'igt'
      translationAttributes = @getFormAttributes(
        @activeServerType, 'translation')
      @primaryAttributes = igtAttributes.concat translationAttributes

    # Return a crucially ordered array of editable secondary data attributes.
    # Note: the returned array is defined using the
    # (to-be-user/system-specified) array defined in the `applicationSettings`
    # model.
    setEditableSecondaryAttributes: ->
      switch @activeServerType
        when 'FieldDB'
          @editableSecondaryAttributes =
            @getFieldDBEditableSecondaryAttributes()
        when 'OLD'
          @editableSecondaryAttributes =
            @getOLDEditableSecondaryAttributes()

    # Maps attributes to their appropriate FieldView subclasses.
    # This is where field-specific configuration should go.
    attribute2fieldView: {}

    attribute2fieldViewFieldDB:
      utterance:                     UtteranceJudgementFieldView
      comments:                      CommentsFieldView

    attribute2fieldViewOLD:
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

    primaryAttributes: []
    editableSecondaryAttributes: []

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

    # Return a crucially ordered array of editable OLD form attributes.
    # An OLD form attribute is editable and secondary iff:
    # - it is secondary, as specified in the app settings model AND
    # - it is not read-only (as also specified in the app settings model)
    getOLDEditableSecondaryAttributes: ->
      secondaryAttributes = @getFormAttributes @activeServerType, 'secondary'
      readonlyAttributes = @getFormAttributes @activeServerType, 'readonly'
      (a for a in secondaryAttributes when a not in readonlyAttributes)

    # Get an array of form attributes (form app settings model) for the
    # specified server type and category (e.g., 'igt' or 'secondary').
    # TODO: remove code duplication from form-handler-base.coffee.
    getFormAttributes: (serverType, category) ->
      switch serverType
        when 'FieldDB' then attribute = 'fieldDBFormCategories'
        when 'OLD' then attribute = 'oldFormCategories'
      try
        globals.applicationSettings.get(attribute)[category]
      catch
        console.log "WARNING: could not get an attributes array for
          #{serverType} and #{category}"
        []

