define [
  './base'
  './../utils/globals'
  './../templates/textarea-button-control'
  'autosize'
], (BaseView, globals, textareaButtonControlTemplate) ->

  # Apply Down Control View
  # -----------------------
  #
  # View for a control for requesting an apply down from an FST-based resource.

  class ApplyDownControlView extends BaseView

    template: textareaButtonControlTemplate
    className: 'apply-down-control-view control-view dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.apply-down':           'applyDown'
      'keydown textarea[name=apply-down]': 'inputKeydown'
      'input textarea[name=apply-down]':   'applyDownInputState'

    inputKeydown: (event) ->
      switch event.which
        when 13 # CTRL+RETURN clicks the "Phonologize" button
          event.stopPropagation()
          if event.ctrlKey
            event.preventDefault()
            @$('button.apply-down').first().click()
        when 27
          console.log 'ESC'
        else
          event.stopPropagation()

    listenToEvents: ->
      super
      @listenTo @model, "applyDownStart", @applyDownStart
      @listenTo @model, "applyDownEnd", @applyDownEnd
      @listenTo @model, "applyDownFail", @applyDownFail
      @listenTo @model, "applyDownSuccess", @applyDownSuccess

    # Write the initial HTML to the page.
    html: ->
      context =
        textareaName: 'apply-down'
        textareaTitle: 'Enter one or more morphologically segmented words here
          and click the “Phonologize” button in order to convert those
          words to their surface representations using this phonology.'
        buttonClass: 'apply-down'
        buttonTitle: 'Enter one or more morphologically segmented words in the
          input on the left and click here in order to convert those words
          to their surface representations using this phonology.'
        buttonText: 'Phonologize'
        resultsContainerClass: 'apply-down-results'
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @disableApplyDownButton()
      @listenToEvents()
      @

    guify: ->
      @buttonify()
      @tooltipify()
      @bordercolorify()
      @autosize()

    tooltipify: ->
      @$('.dative-tooltip').not('button.apply-down')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-tooltip.apply-down')
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
    # Apply Down
    ############################################################################

    applyDownInputState: ->
      input = @$('textarea[name=apply-down]').val()
      applyDownButtonDisabled =
        @$('button.apply-down').button 'option', 'disabled'
      if input
        if applyDownButtonDisabled then @enableApplyDownButton()
      else
        if not applyDownButtonDisabled then @disableApplyDownButton()

    applyDown: ->
      input = @$('textarea[name=apply-down]').val()
      @model.applyDown input

    applyDownStart: ->
      @spin 'button.apply-down', '50%', '120%'
      @disableApplyDownButton()

    applyDownEnd: ->
      @stopSpin 'button.apply-down'
      @enableApplyDownButton()

    applyDownFail: (error) ->
      Backbone.trigger 'phonologyApplyDownFail', error, @model.get('id')

    applyDownSuccess: (applyDownResults) ->
      Backbone.trigger 'phonologyApplyDownSuccess', @model.get('id')
      @displayApplyDownResultsInTable applyDownResults

    displayApplyDownResultsInTable: (applyDownResults) ->
      table = ['<table class="io-results-table">
        <tr><th>inputs</th><th>outputs</th></tr>']
      oddEven = 0
      for uf, sfSet of applyDownResults
        if oddEven is 0
          oddEven = 1
          table.push "<tr class='even'><td>#{uf}</td>
            <td>#{sfSet.join ', '}</td></tr>"
        else
          oddEven = 0
          table.push "<tr><td>#{uf}</td><td>#{sfSet.join ', '}</td></tr>"
      table.push "</table>"
      @$('.apply-down-results')
        .hide()
        .html table.join('')
        .slideDown()

    disableApplyDownButton: -> @$('button.apply-down').button 'disable'

    enableApplyDownButton: -> @$('button.apply-down').button 'enable'

