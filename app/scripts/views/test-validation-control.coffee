define [
  './base'
  './../utils/globals'
  './../templates/textarea-control'
  'autosize'
], (BaseView, globals, textareaButtonControlTemplate) ->

  # Test Validation Control View
  # ----------------------------
  #
  # View for a control for testing how input validation works on a specific
  # field.

  class TestValidationControlView extends BaseView

    # Change this in subclasses. Valid possible values are
    # - 'orthographic transcription'
    # - 'narrow phonetic transcription'
    # - 'broad phonetic transcription'
    # - 'morpheme break'
    targetField: 'orthographic transcription'

    # Change this in subclasses to something that corresponds to `@targetField`.
    textareaLabel: 'Orthographic transcription validation test'

    template: textareaButtonControlTemplate
    className: 'test-validation-control-view control-view dative-widget-center'

    # Return a validator (a `RegExp` instance) that returns `true` if the input
    # of the specified field is valid.
    getValidator: ->
      if @_validator then return @_validator
      switch @targetField
        when 'orthographic transcription'
          @_validator = @getOrthographicValidator()
        when 'narrow phonetic transcription'
          @_validator = @getNarrowPhoneticValidator()
        when 'broad phonetic transcription'
          @_validator = @getBroadPhoneticValidator()
        else
          @_validator = @getMorphemeBreakValidator()
      @_validator

    # Return a RegExp that validates morpheme break values. This allows:
    # - graphs from the storage orthography XOR phonemic inventory,
    # - capitalized graphs from the storage orthography XOR phonemic inventory,
    # - morpheme delimiters, and
    # - the space character
    getMorphemeBreakValidator: ->
      if @model.get 'morpheme_break_is_orthographic'
        inventory = @getInventoryFromStorageOrthography()
      else
        inventory = @model.get 'phonemic_inventory'
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        delimiters =
          (@utils.escapeRegexChars(d) for d in @model.get('morpheme_delimiters').split(','))
        # A phonemic inventory should not have its graphs automatically
        # capitalized since capitalization may have phonological meaning.
        if @model.get 'morpheme_break_is_orthographic'
          capitalizedGraphs =
            (@utils.escapeRegexChars(@utils.capitalize(g)) for g in graphs)
          elements = escapedGraphs.concat delimiters, capitalizedGraphs
        else
          elements = escapedGraphs.concat delimiters
        new RegExp "^(#{elements.join '|'}| )*$"
      else
        null

    # Return a RegExp that validates orthographic transcription values. This
    # allows:
    # - graphs from the storage orthography,
    # - capitalized graphs from the storage orthography,
    # - punctuation characters, and
    # - the space character
    getOrthographicValidator: ->
      inventory = @getInventoryFromStorageOrthography()
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        punctuation =
          (@utils.escapeRegexChars(p) for p in @model.get('punctuation').split(''))
        capitalizedGraphs =
          (@utils.escapeRegexChars(@utils.capitalize(g)) for g in graphs)
        elements = escapedGraphs.concat punctuation, capitalizedGraphs
        new RegExp "^(#{elements.join '|'}| )*$"
      else
        null

    # Get an inventory string (i.e., an orthography) from the storage
    # orthography object in application settings.
    getInventoryFromStorageOrthography: ->
      orthography = @model.get 'storage_orthography'
      if orthography
        orthography.orthography
      else
        null

    # Return a RegExp that validates narrow phonetic transcription values. This
    # allows:
    # - graphs from the narrow phonetic inventory and
    # - the space character
    getNarrowPhoneticValidator: ->
      inventory = @model.get 'narrow_phonetic_inventory'
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        new RegExp "^(#{escapedGraphs.join '|'}| )*$"
      else
        null

    # Return a RegExp that validates phonetic transcription values. This
    # allows:
    # - graphs from the broad phonetic inventory and
    # - the space character
    getBroadPhoneticValidator: ->
      inventory = @model.get 'broad_phonetic_inventory'
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        new RegExp "^(#{escapedGraphs.join '|'}| )*$"
      else
        null

    initialize: (options) ->
      @_validator = null
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    resetValidator: ->
      @_validator = null

    listenToEvents: ->
      super
      @listenTo @model, 'change', @resetValidator

    events:
      'input textarea[name=test-validation]':   'testValidation'

    testValidationInputAbility: ->
      if @getValidator()
        @enableTestValidationInput()
      else
        @disableTestValidationInput()

    # Write the initial HTML to the page.
    html: ->
      title = "Enter #{@utils.indefiniteDeterminer @targetField}
        #{@targetField} value here to see if it is valid."
      context =
        textareaLabel: @textareaLabel
        textareaLabelTitle: title
        textareaName: 'test-validation'
        textareaTitle: title
        resultsContainerClass: @resultsContainerClass
      @$el.html @template(context)

    resultsContainerClass: 'test-validation-results'

    render: ->
      @html()
      @guify()
      @testValidationInputAbility()
      @listenToEvents()
      @

    guify: ->
      @tooltipify()
      @bordercolorify()
      @autosize()

    tooltipify: ->
      @$('.dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo

    autosize: -> @$('textarea').autosize append: false

    testValidationInputState: ->
      validator = @getValidator()
      if validator
        @enableTestValidationInput()
      else
        @disableTestValidationInput()

    testValidation: ->
      input = @$('textarea[name=test-validation]').val()
      validator = @getValidator()
      if validator
        if validator.test input
          @setStateValid()
        else
          @setStateInvalid()
      else
        @setStateNoState()

    setStateNoState: ->
      @$(".#{@resultsContainerClass}").html ''

    setStateInvalid: ->
      @$(".#{@resultsContainerClass}")
        .html '<i class="ui-state-error-color fa fa-fw fa-2x fa-times-circle"></i>'

    setStateValid: ->
      @$(".#{@resultsContainerClass}")
        .html '<i class="ui-state-ok fa fa-fw fa-2x fa-check-circle"></i>'

    disableTestValidationInput: ->
      @$('textarea[name=test-validation]').attr 'disabled', true

    enableTestValidationInput: ->
      @$('textarea[name=test-validation]').attr 'disabled', false


