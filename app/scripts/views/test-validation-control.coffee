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

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    listenToEvents: ->
      super

    events:
      'input textarea[name=test-validation]':   'testValidation'

    testValidationInputAbility: ->
      if @model.getInputValidator @targetField
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
      validator = @model.getInputValidator @targetField
      if validator
        @enableTestValidationInput()
      else
        @disableTestValidationInput()

    testValidation: ->
      input = @$('textarea[name=test-validation]').val()
      validator = @model.getInputValidator @targetField
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


