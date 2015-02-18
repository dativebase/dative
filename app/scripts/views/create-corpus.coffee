define [
  'backbone'
  './base'
  './../templates/create-corpus'
], (Backbone, BaseView, createCorpusTemplate) ->

  # Create Corpus View
  # ------------------
  #
  # View for creating a new corpus. Just a single text input and a button.

  class CreateCorpusView extends BaseView

    tagName: 'div'
    className: ['create-corpus-widget ui-widget ui-widget-content ui-corner-all',
      'dative-widget-center'].join ' '

    initialize: (options) ->
      @visible = false
      @submitAttempted = false
      @requestPending = false
      @inputsValid = false

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo Backbone, 'newCorpusStart', @newCorpusStart
      @listenTo Backbone, 'newCorpusEnd', @newCorpusEnd
      @listenTo Backbone, 'newCorpusSuccess', @newCorpusSuccess
      @listenTo Backbone, 'newCorpusFail', @newCorpusFail

    template: createCorpusTemplate

    render: ->
      @$el.html @template()
      @guify()
      @listenToEvents()
      @

    events:
      'keyup input[name=corpus-title]': 'validate'
      'click button.request-create-corpus': 'requestCreateCorpus'
      'keydown button.request-create-corpus': 'requestCreateCorpusKeys'
      'keydown input[name=corpus-title]': 'requestCreateCorpusKeys'

    newCorpusStart: (newCorpusTitle) ->
      @disableCreateCorpusButton()
      @spin "Requesting creation of a new corpus entitled “#{newCorpusTitle}”"

    newCorpusEnd: ->
      @requestPending = false
      @hideTooltip()
      @enableCreateCorpusButton()
      @stopSpin()

    newCorpusSuccess: (newCorpusTitle) ->
      @showCorpusCreateSuccessMessage "Successfully created a corpus entitled “#{newCorpusTitle}”"

    newCorpusFail: (reason) ->
      @showCorpusCreateErrorMessage reason

    corpusCreateMessagePosition:
      my: 'left top'
      at: 'right+195 top'
      collision: 'flipfit'

    showCorpusCreateSuccessMessage: (message) ->
      @closeCorpusCreateErrorMessage()
      $target = @$('.request-create-corpus-success-tooltip').first()
      $target
        .tooltip
          items: 'span'
          tooltipClass: 'ui-state-highlight'
          content: message
          position: @corpusCreateMessagePosition
      $target.tooltip 'open'

    closeCorpusCreateErrorMessage: ->
      $target = @$('.request-create-corpus-error-tooltip').first()
      if $target.tooltip 'instance' then $target.tooltip 'close'

    closeCorpusCreateSuccessMessage: ->
      $target = @$('.request-create-corpus-success-tooltip').first()
      if $target.tooltip 'instance' then $target.tooltip 'close'

    showCorpusCreateErrorMessage: (message) ->
      @closeCorpusCreateSuccessMessage()
      $target = @$('.request-create-corpus-error-tooltip').first()
      $target
        .tooltip
          items: 'span'
          tooltipClass: 'ui-state-error'
          content: message
          position: @corpusCreateMessagePosition
      $target.tooltip 'open'

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '50%', left: '97%'}

    spin: (tooltipMessage=null) ->
      @$('.dative-widget-header').first().spin @spinnerOptions()
      if tooltipMessage then @showTooltip tooltipMessage, 'success'

    tooltipPosition:
      my: "left+610 top+8"
      at: "left top"
      collision: "flipfit"

    showTooltip: (tooltipMessage) ->
      @$('.dative-widget-header').first()
        .tooltip
          items: 'div'
          content: tooltipMessage
          position: @tooltipPosition
        .tooltip 'open'

    hideTooltip: ->
      $header = @$('.dative-widget-header').first()
      if $header.tooltip 'instance'
        $header.tooltip 'close'

    stopSpin: ->
      @$('.dative-widget-header').first().spin false

    requestCreateCorpus: ->
      @submitAttempted = true
      corpusTitle = @validate()
      if @inputsValid
        @disableCreateCorpusButton()
        @trigger 'request:createCorpus', corpusTitle
        @requestPending = true

    requestCreateCorpusKeys: (event) ->
      if event.which is 13
        @stopEvent event
        $createCorpusButton = @$('button.request-create-corpus')
        disabled = $createCorpusButton.button 'option', 'disabled'
        if not disabled then $createCorpusButton.click()

    disableCreateCorpusButton: ->
      @focusTitleInput()
      @$('button.request-create-corpus').button 'disable'

    enableCreateCorpusButton: ->
      @$('button.request-create-corpus').button 'enable'

    focusTitleInput: ->
      @$('input[name=corpus-title]').first().focus()

    validate: ->
      corpusTitle = @$('input[name=corpus-title]').val() or false
      if corpusTitle then @hideErrorMsg()
      errorMsg = null
      if not corpusTitle
        errorMsg = 'required'
      @inputsValid = if errorMsg then false else true
      if @submitAttempted
        if @inputsValid
          @hideErrorMsg()
          if not @requestPending then @enableCreateCorpusButton()
        else
          @showErrorMsg errorMsg
          @disableCreateCorpusButton()
      corpusTitle

    showErrorMsg: (errorMsg) ->
      @$(".corpus-title-error").first().stop().text(errorMsg).fadeIn()

    hideErrorMsg: -> @$(".corpus-title-error").first().stop().fadeOut()

    # Tabindices=0 and jQueryUI colors
    # TODO @jrwdunham: this could be a method defined once in BaseView, I think.
    tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors().defBo)
        .attr('tabindex', 0)

    guify: ->

      position =
        my: "right-95px center"
        at: "left center"
        collision: "flipfit"

      @$('input[name=corpus-title]')
        .tooltip position: position

      @$('button.request-create-corpus')
        .button()
        .tooltip position: position

      @$('.dative-create-corpus-failed').hide()
      @tabindicesNaught()

    closeGUI: ->
      @visible = false
      @$el.slideUp()
      @closeAllTooltips()

    openGUI: ->
      @visible = true
      @$el.slideDown()

    hide: ->
      @visible = false
      @$el.hide()

    show: ->
      @visible = true
      @$el.show()

