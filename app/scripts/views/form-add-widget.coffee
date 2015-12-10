define [
  './resource-add-widget'
  './textarea-field'
  './relational-select-field'
  './relational-select-field-with-add-button'
  './elicitation-method-select-field-with-add-button'
  './speaker-select-field-with-add-button'
  './syntactic-category-select-field-with-add-button'
  './user-select-field-with-add-button'
  './multi-element-tag-field'
  './utterance-judgement-field'
  './comments-field'
  './transcription-base-field'
  './transcription-grammaticality-field'
  './translations-field'
  './person-select-field'
  './user-select-field'
  './source-select-field'
  './source-select-via-search-field'
  './files-select-via-search-field'
  './required-select-field'
  './date-field'
  './morpheme-break-field'
  './morpheme-gloss-field'
  './../models/form'
  './../utils/globals'
], (ResourceAddWidgetView, TextareaFieldView, RelationalSelectFieldView,
  RelationalSelectFieldWithAddButtonView,
  ElicitationMethodSelectFieldWithAddButtonView,
  SpeakerSelectFieldWithAddButtonView,
  SyntacticCategorySelectFieldWithAddButtonView,
  UserSelectFieldWithAddButtonView, MultiElementTagFieldView,
  UtteranceJudgementFieldView, CommentsFieldView, TranscriptionBaseFieldView,
  TranscriptionGrammaticalityFieldView, TranslationsFieldView,
  PersonSelectFieldView, UserSelectFieldView, SourceSelectFieldView,
  SourceSelectViaSearchFieldView, FilesSelectViaSearchFieldView,
  RequiredSelectFieldView, DateFieldView, MorphemeBreakFieldView,
  MorphemeGlossFieldView, FormModel, globals) ->


  class StatusSelectFieldView extends RequiredSelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options


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


  class ElicitorSelectFieldWithAddButtonView extends UserSelectFieldWithAddButtonView

    attributeName: 'elicitor'


  class VerifierSelectFieldWithAddButtonView extends UserSelectFieldWithAddButtonView

    attributeName: 'verifier'


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
      narrow_phonetic_transcription: TranscriptionBaseFieldView
      phonetic_transcription:        TranscriptionBaseFieldView
      transcription:                 TranscriptionGrammaticalityFieldView255
      morpheme_break:                MorphemeBreakFieldView
      morpheme_gloss:                MorphemeGlossFieldView
      syntax:                        TextareaFieldView1023
      semantics:                     TextareaFieldView1023
      translations:                  TranslationsFieldView
      elicitation_method:            ElicitationMethodSelectFieldWithAddButtonView
      syntactic_category:            SyntacticCategorySelectFieldWithAddButtonView
      speaker:                       SpeakerSelectFieldWithAddButtonView
      elicitor:                      ElicitorSelectFieldWithAddButtonView
      verifier:                      VerifierSelectFieldWithAddButtonView
      source:                        SourceSelectViaSearchFieldView
      status:                        StatusSelectFieldView
      date_elicited:                 DateFieldView
      tags:                          MultiElementTagFieldView
      files:                         FilesSelectViaSearchFieldView

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

    # Get an array of form attributes (from the app settings model) for the
    # specified server type and category (e.g., 'igt' or 'secondary').
    # TODO: remove code duplication from form-handler-base.coffee.
    getFormAttributes: (serverType, category) ->
      try
        globals.applicationSettings.get('resources')
          .forms.fieldsMeta[serverType][category]
      catch
        console.log "WARNING: could not get an attributes array for
          #{serverType} and #{category}"
        []

    # Return a JS object representing an empty resource model: note that this
    # crucially "empties" the editable attributes; that is, a resource's id,
    # its enterer, etc., will not be represented in the returned model object.
    getEmptyModelObject: ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super
        when 'FieldDB'
          modelDefaults = @utils.clone @model.defaults()
          emptyModelObject = {}
          editableAttributes =
            @editableSecondaryAttributes.concat @primaryAttributes
          for attribute in editableAttributes
            if attribute of modelDefaults
              emptyModelObject[attribute] = modelDefaults[attribute]
          emptyModelObject.datumFields = modelDefaults.datumFields
          emptyModelObject

    # This returns the options for our forced-choice field views. we add
    # options for the `status` attribute.
    getOptions: ->
      options = super
      options.statuses = [
        'tested'
        'requires testing'
      ]
      options

    # The FormAddWidgetView has a special render method; it refreshes all of
    # its field views with newly retrieved `options`. This is a bit of a hack/
    # overkill. The purpose is so that the grammaticality options in the
    # relevant select menus will have the current options when an OLD app
    # settings is updated.
    render: ->
      super
      options = @getOptions()
      for fv in @fieldViews()
        fv.options = options
        fv.refresh()
      @

