define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './required-select-field'
  './orthography-select-field-with-add-button'
  './users-select-via-search-field'
  './textarea-input'
  './../models/old-application-settings'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, RequiredSelectFieldView,
  OrthographySelectFieldWithAddButtonView, UsersSelectViaSearchFieldView,
  TextareaInputView, OLDApplicationSettingsModel) ->


  # Field view for selecting an existing orthography as "input orthography";
  # also has a button for creating a new orthography in the page.
  class InputOrthographySelectFieldWithAddButtonView extends OrthographySelectFieldWithAddButtonView

    attributeName: 'input_orthography'


  # Field view for selecting an existing orthography as "output orthography";
  # also has a button for creating a new orthography in the page.
  class OutputOrthographySelectFieldWithAddButtonView extends OrthographySelectFieldWithAddButtonView

    attributeName: 'output_orthography'


  # Textarea field view that allows 255 characters max.
  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options



  # Field view for specifying a language name or (ISO 639-3) three-leter Id
  # such that changes to the "counterpart" value may cause changes to the value
  # controlled by this field view.
  # For example, the field view for the `metalanguage_id` attribute inherits
  # from this and when the `metalanguage_name` value changes then this value
  # will change to match that name value, assuming that the *user* has not
  # specified something here. That is, user-specified values trump
  # system-specified ones.
  # Note that this view assumes that jQueryUI `.autocomplete` is being used by
  # the input view of this field.
  class LanguageWithCounterpartFieldView extends TextareaFieldView

    # Change this in sub-classes to the name of our counterpart attribute,
    # i.e., the attribute that we want to listen for changes on.
    getCounterpartAttribute: -> 'xxxxxx'

    # Change this in sub-classes so that it returns an object that maps
    # counterpart values to values appropriate for this field.
    getCounterpartMapper: -> {}

    listenToEvents: ->
      super
      @listenTo @model, @getCounterpartChangeEvent(), @counterpartChanged

    getCounterpartChangeEvent: -> "change:#{@getCounterpartAttribute()}"

    # The value of our counterpart attribute has changed. If our current value
    # is '' or if the system was the last agent to specify our current value,
    # then we change our current value so that it accords with the value of our
    # counterpart.
    counterpartChanged: ->
      if @model.get(@context.attribute) is '' or
      @systemSetVal
        counterpartVal = @model.get @getCounterpartAttribute()
        matchingVal = @getCounterpartMapper()[counterpartVal]
        if matchingVal
          @$("textarea[name=#{@context.attribute}]").val matchingVal
          @systemSetToModel()

    initialize: (options) ->
      super options
      if @model.get(@context.attribute)
        @systemSetVal = false
        @userSetVal = true
      else
        @systemSetVal = true
        @userSetVal = false
      # @events["autocompleteselect .#{@context.class}"] = 'userSetToModel'
      # @events['change'] = 'userSetToModel'
      # @events['input'] = 'userSetToModel'
      # @events['selectmenuchange'] = 'userSetToModel'
      # @events['menuselect'] = 'userSetToModel'

    events:
      'autocompleteselect': 'userSetToModel'
      'change':             'userSetToModel'
      'input':              'userSetToModel'
      'selectmenuchange':   'userSetToModel'
      'menuselect':         'userSetToModel'

    # We divide our `setToModel` API into one for the system and one for the
    # user so that we can keep track of who set to the model and allow the user
    # to take precedence over the system.

    systemSetToModel: ->
      @systemSetVal = true
      @userSetVal = false
      @setToModel()

    userSetToModel: ->
      @userSetVal = true
      @systemSetVal = false
      @setToModel()


  # The language id fields use this input view: it autosuggests ISO 639-3
  # language Id values.
  class LanguageIdAutoCompleteInputView extends TextareaInputView

    render: ->
      super
      @$("textarea.#{@context.class}").first().autocomplete
        source: @context.options.languageIds
      @

  # This is the field view for the language id attributes. It auto-suggests ISO
  # 639-3 Id values and it intelligently changes the value to accord with the
  # language name of the relevant counterpart name attribute.
  class LanguageIdAutoCompleteFieldView extends LanguageWithCounterpartFieldView

    getInputView: ->
      new LanguageIdAutoCompleteInputView @context

    initialize: (options) ->
      options.domAttributes =
        maxlength: 3
      super options

    # If our attribute is `metalanguage_id`, then our counterpart attribute
    # will be `metalanguage_name`, etc.
    getCounterpartAttribute: ->
      attr = @context.attribute
      "#{attr[...(attr.length - 2)]}name"

    # We want to look in the object that maps ISO 639-3 Ref Name values to ISO
    # 639-3 Id values.
    getCounterpartMapper: ->
      @context.options.languageRefNamesToIds


  # The language name fields use this input view: it autosuggests ISO 639-3
  # language Ref Name values.
  class LanguageRefNameAutoCompleteInputView extends TextareaInputView

    render: ->
      super
      @$("textarea.#{@context.class}").first().autocomplete
        source: @context.options.languageRefNames
      @


  # This is the field view for the language name attributes. It auto-suggests
  # ISO 639-3 Ref Name values and it intelligently changes the value to accord
  # with the language id of the relevant counterpart name attribute.
  class LanguageRefNameAutoCompleteFieldView extends LanguageWithCounterpartFieldView

    getInputView: ->
      new LanguageRefNameAutoCompleteInputView @context

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options

    getCounterpartAttribute: ->
      attr = @context.attribute
      "#{attr[...(attr.length - 4)]}id"

    getCounterpartMapper: ->
      @context.options.languageIdsToRefNames

  # This is a selectmenu-based field for the `_validation`-suffixed attributes.
  class ValidationSelectFieldView extends RequiredSelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options


  class BooleanSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'booleans'
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


  # OLD Application Settings Add Widget View
  # ----------------------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # OLD application settings model and updating an existing one.

  ##############################################################################
  # OLD Application Settings Add Widget
  ##############################################################################

  class OLDApplicationSettingsAddWidgetView extends ResourceAddWidgetView

    resourceName: 'oldApplicationSettings'
    serverSideResourceName: 'applicationsettings'
    resourceModel: OLDApplicationSettingsModel

    getHeaderTitle: -> 'Update the OLD application settings'

    # TODOs:
    # 2. language id fields should only allow ISO 639-3 values.

    # We override the superclass's `submitForm` because we want to always issue
    # a POST (create) request and never a PUT (update) one.
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
          Backbone.trigger "#{@addUpdateType}#{@resourceNameCapitalized}Fail",
            msg, @model
          @enableForm()
        else
          @model.collection.addResource @model
      else
        Backbone.trigger("#{@addUpdateType}#{@resourceNameCapitalized}Fail",
          'Please make some changes before attempting to save.', @model)

    attribute2fieldView:
      object_language_name: LanguageRefNameAutoCompleteFieldView
      metalanguage_name: LanguageRefNameAutoCompleteFieldView
      morpheme_delimiters: TextareaFieldView255
      grammaticalities: TextareaFieldView255
      orthographic_validation: ValidationSelectFieldView
      narrow_phonetic_validation: ValidationSelectFieldView
      broad_phonetic_validation: ValidationSelectFieldView
      morpheme_break_validation: ValidationSelectFieldView
      morpheme_break_is_orthographic: BooleanSelectFieldView
      storage_orthography: OrthographySelectFieldWithAddButtonView
      input_orthography: InputOrthographySelectFieldWithAddButtonView
      output_orthography: OutputOrthographySelectFieldWithAddButtonView
      unrestricted_users: UsersSelectViaSearchFieldView
      object_language_id: LanguageIdAutoCompleteFieldView
      metalanguage_id: LanguageIdAutoCompleteFieldView

    primaryAttributes: [
      'object_language_name'
      'object_language_id'
      'metalanguage_name'
      'metalanguage_id'
      'metalanguage_inventory'
      'orthographic_validation'
      'narrow_phonetic_inventory'
      'narrow_phonetic_validation'
      'broad_phonetic_inventory'
      'broad_phonetic_validation'
      'morpheme_break_is_orthographic'
      'morpheme_break_validation'
      'phonemic_inventory'
      'morpheme_delimiters'
      'punctuation'
      'grammaticalities'
      'storage_orthography'
      'input_orthography'
      'output_orthography'
      'unrestricted_users'
    ]

    # Return an array of objects for autocompleting ISO 639-3 language Ids.
    getLanguageIds: ->
      if not @_languageIds
        @_languageIds = ({label: "#{l.Id} (#{l.Ref_Name})", value: l.Id} \
          for l in @options.languages)
      @_languageIds

    # Return an array of objects for autocompleting ISO 639-3 language Ref
    # Names.
    getLanguageRefNames: ->
      if not @_languageRefNames
        @_languageRefNames = ({label: "#{l.Ref_Name} (#{l.Id})", value: l.Ref_Name} \
          for l in @options.languages)
        # We give an array of language Ids to our model too because our model
        # will use it for validating the language id values when a create/save
        # request is made.
        @model.languageRefNames = (l.Id for l in @options.languages)
      @_languageRefNames

    # Return an object that maps ISO 639-3 language Ids to their corresponding
    # Ref Name values; used to auto-fill language name fields with values when
    # a language id value is specified.
    getLanguageIdsToRefNames: ->
      if not @_languageIdsToRefNames
        @_languageIdsToRefNames = {}
        for l in @options.languages
          @_languageIdsToRefNames[l.Id] = l.Ref_Name
      @_languageIdsToRefNames

    # Return an object that maps ISO 639-3 language Ref Names to their
    # corresponding Ids; used to auto-fill language id fields with values when
    # a language name value is specified.
    getLanguageRefNamesToIds: ->
      if not @_languageRefNamesToIds
        @_languageRefNamesToIds = {}
        for l in @options.languages
          @_languageRefNamesToIds[l.Ref_Name] = l.Id
      @_languageRefNamesToIds

    getOptions: ->
      options = super
      validations = ['None', 'Warning', 'Error']
      options.orthographic_validations = validations
      options.narrow_phonetic_validations = validations
      options.broad_phonetic_validations = validations
      options.morpheme_break_validations = validations
      options.booleans = [true, false]
      @options = options
      options.languageIds = @getLanguageIds()
      options.languageRefNames = @getLanguageRefNames()
      options.languageIdsToRefNames = @getLanguageIdsToRefNames()
      options.languageRefNamesToIds = @getLanguageRefNamesToIds()
      options

    # We have successfully created a new OLD application settings resource.
    addResourceSuccess: ->
      super

      # Here we are storing our new grammaticalities in `globals`.
      grammaticalities = @model.get('grammaticalities').split ','
      grammaticalitiesData =
        data:
          grammaticalities: grammaticalities
      @storeOptionsDataGlobally grammaticalitiesData

      @originalModelCopy = @copyModel @model

