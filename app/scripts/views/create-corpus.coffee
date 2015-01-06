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
      @inputsValid = false
      @listenTo Backbone, 'createCorpusEnd', @stopSpin

    template: createCorpusTemplate

    render: ->
      @$el.html @template()
      @guify()
      @

    events:
      'keyup input[name=corpus-name]': 'validate'
      'click button.request-create-corpus': 'requestCreateCorpus'
      'keydown button.request-create-corpus': 'requestCreateCorpusKeys'
      'keydown input[name=corpus-name]': 'requestCreateCorpusKeys'

    requestCreateCorpus: ->
      @submitAttempted = true
      corpusName = @validate()
      if @inputsValid
        @disableCreateCorpusButton()
        @trigger 'request:createCorpus', corpusName

    requestCreateCorpusKeys: (event) ->
      if event.which is 13
        @stopEvent event
        $createCorpusButton = @$('button.request-create-corpus')
        disabled = $createCorpusButton.button 'option', 'disabled'
        if not disabled then $createCorpusButton.click()

    disableCreateCorpusButton: ->
      @$('input[name=corpus-name]').first().focus()
      @$('button.request-create-corpus').button 'disable'

    enableCreateCorpusButton: ->
      @$('button.request-create-corpus').button 'enable'

    validate: ->
      corpusName = @$('input[name=corpus-name]').val() or false
      if corpusName then @hideErrorMsg()
      errorMsg = null
      if not corpusName
        errorMsg = 'required'
      @inputsValid = if errorMsg then false else true
      if @submitAttempted
        if @inputsValid
          @hideErrorMsg()
          @enableCreateCorpusButton()
        else
          @showErrorMsg errorMsg
          @disableCreateCorpusButton()
      corpusName

    showErrorMsg: (errorMsg) ->
      @$(".corpus-name-error").first().stop().text(errorMsg).fadeIn()

    hideErrorMsg: -> @$(".corpus-name-error").first().stop().fadeOut()

    # Tabindices=0 and jQueryUI colors
    # TODO @jrwdunham: this could be a method defined once in BaseView, I think.
    tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    guify: ->

      @$('input[name=corpus-name]')
        .tooltip
          position:
            my: "right-95px center"
            at: "left center"
            collision: "flipfit"

      @$('button.request-create-corpus')
        .button()
        .tooltip()

      @$('.dative-create-corpus-failed').hide()
      @tabindicesNaught()

    closeGUI: ->
      @visible = false
      @$el.slideUp()

    openGUI: ->
      @visible = true
      @$el.slideDown()

    hide: ->
      @visible = false
      @$el.hide()

    show: ->
      @visible = true
      @$el.show()

