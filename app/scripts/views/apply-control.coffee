define [
  './base'
  './../utils/globals'
  './../templates/textarea-button-control'
  'autosize'
], (BaseView, globals, textareaButtonControlTemplate) ->

  # Apply Control View
  # ------------------
  #
  # View for a control for making an apply request against an FST-based
  # resource; this generalizes over apply up and apply down requests.

  class ApplyControlView extends BaseView

    direction: 'down'

    template: textareaButtonControlTemplate
    className: ->
      "apply-#{@direction}-control-view control-view dative-widget-center"

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()
      @events["click button.apply-#{@direction}"] = 'apply'
      @events["keydown textarea[name=apply-#{@direction}]"] = 'inputKeydown'
      @events["input textarea[name=apply-#{@direction}]"] = 'applyInputState'

    events: {}

    inputKeydown: (event) ->
      switch event.which
        when 13 # CTRL+RETURN clicks the "Apply" button
          event.stopPropagation()
          if event.ctrlKey
            event.preventDefault()
            @$("button.apply-#{@direction}").first().click()
        when 27
          false
        else
          event.stopPropagation()

    listenToEvents: ->
      super
      @listenTo @model, "applyStart", @applyStart
      @listenTo @model, "applyEnd", @applyEnd
      @listenTo @model, "applyFail", @applyFail
      @listenTo @model, "applySuccess", @applySuccess
      @listenTo @model, "change:compile_succeeded", @compileSucceededChanged

    compileSucceededChanged: ->
      if @model.get('compile_succeeded') is false
        @disableApplyButton()
        @disableApplyInput()
      else
        @enableApplyButton()
        @enableApplyInput()

    applyInputAbility: ->
      if @model.get('compile_succeeded') is false
        @disableApplyInput()
      else
        @enableApplyInput()

    # Write the initial HTML to the page.
    html: ->
      context =
        textareaName: "apply-#{@direction}"
        textareaTitle: 'Enter one or more morphologically segmented words here
          and click the “Phonologize” button in order to convert those
          words to their surface representations using this phonology.'
        buttonClass: "apply-#{@direction}"
        buttonTitle: 'Enter one or more morphologically segmented words in the
          input on the left and click here in order to convert those words
          to their surface representations using this phonology.'
        buttonText: 'Phonologize'
        resultsContainerClass: "apply-#{@direction}-results"
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @disableApplyButton()
      @applyInputAbility()
      @listenToEvents()
      @

    guify: ->
      @buttonify()
      @tooltipify()
      @bordercolorify()
      @autosize()

    tooltipify: ->
      @$('.dative-tooltip').not("button.apply-#{@direction}")
        .tooltip position: @tooltipPositionLeft('-20')
      @$(".dative-tooltip.apply-#{@direction}")
        .tooltip position: @tooltipPositionRight('+20')

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo

    autosize: -> @$('textarea').autosize append: false

    buttonify: -> @$('button').button()

    spinnerOptions: (top='50%', left='-170%') ->
      options = super
      options.top = top
      options.left = left
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: (selector='.spinner-container', top='50%', left='-170%') ->
      @$(selector).spin @spinnerOptions(top, left)

    stopSpin: (selector='.spinner-container') ->
      @$(selector).spin false

    ############################################################################
    # Apply 
    ############################################################################

    applyInputState: ->
      input = @$("textarea[name=apply-#{@direction}]").val()
      applyButtonDisabled =
        @$("button.apply-#{@direction}").button 'option', 'disabled'
      if input
        if applyButtonDisabled then @enableApplyButton()
      else
        if not applyButtonDisabled then @disableApplyButton()

    apply: ->
      input = @$("textarea[name=apply-#{@direction}]").val()
      @model.apply input

    applyStart: ->
      @spin "button.apply-#{@direction}", '50%', '120%'
      @disableApplyButton()

    applyEnd: ->
      @stopSpin "button.apply-#{@direction}"
      @enableApplyButton()

    applyFail: (error) ->
      Backbone.trigger "phonologyApply#{@utils.capitalize @direction}Fail",
        error, @model.get('id')

    applySuccess: (applyResults) ->
      Backbone.trigger "phonologyApply#{@utils.capitalize @direction}Success",
        @model.get('id')
      @displayApplyResultsInTable applyResults

    displayApplyResultsInTable: (applyResults) ->
      table = ['<table class="io-results-table">
        <tr><th>inputs</th><th>outputs</th></tr>']
      oddEven = 0
      for uf, sfSet of applyResults
        if oddEven is 0
          oddEven = 1
          table.push "<tr class='even'><td>#{uf}</td>
            <td>#{sfSet.join ', '}</td></tr>"
        else
          oddEven = 0
          table.push "<tr><td>#{uf}</td><td>#{sfSet.join ', '}</td></tr>"
      table.push "</table>"
      @$(".apply-#{@direction}-results")
        .hide()
        .html table.join('')
        .slideDown()

    disableApplyButton: -> @$("button.apply-#{@direction}").button 'disable'
    enableApplyButton: -> @$("button.apply-#{@direction}").button 'enable'

    disableApplyInput: ->
      @$("textarea[name=apply-#{@direction}]").attr 'disabled', true

    enableApplyInput: ->
      @$("textarea[name=apply-#{@direction}]").attr 'disabled', false


