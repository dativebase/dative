define [
  'backbone'
  './base'
  './../templates/edit-corpus'
], (Backbone, BaseView, editCorpusTemplate) ->

  # Edit Corpus View
  # ----------------
  #
  # View for modifying the title and description of a corpus.

  class EditCorpusView extends BaseView

    tagName: 'div'
    className: ['edit-corpus-widget ui-widget ui-widget-content ui-corner-all',
      'dative-widget-center'].join ' '

    initialize: (options) ->
      @visible = false
      @submitAttempted = false
      @inputsValid = false
      # DELETE? @listenTo Backbone, 'updateCorpusEnd', @stopSpin

    template: editCorpusTemplate

    render: ->
      @$el.html @template(@model.attributes)
      @guify()
      @

    events:
      'keyup textarea[name=title]': 'validate'
      'keyup textarea[name=description]': 'validate'
      'click button.request-edit-corpus': 'requestEditCorpus'
      'keydown textarea[name=title]': 'submitWithEnter'
      'keydown textarea[name=description]': 'submitWithEnter'

    requestEditCorpus: ->
      @submitAttempted = true
      {title, description} = @validate()
      if @inputsValid
        @disableEditCorpusButton()
        @trigger 'request:editCorpus', title, description

    disableEditCorpusButton: ->
      @$('textarea[name=title]').first().focus()
      @$('button.request-edit-corpus').button 'disable'

    enableEditCorpusButton: ->
      @$('button.request-edit-corpus').button 'enable'

    validate: ->
      title = @$('textarea[name=title]').val() or false
      description = @$('textarea[name=description]').val() or false
      if title then @hideTitleErrorMsg()
      if description then @hideDescriptionErrorMsg()

      titleErrorMsg = if not title then 'required' else null
      descriptionErrorMsg = if not description then 'required' else null

      @inputsValid = if titleErrorMsg or descriptionErrorMsg then false else true

      if @submitAttempted
        if @inputsValid
          @hideTitleErrorMsg()
          @hideDescriptionErrorMsg()
          @enableEditCorpusButton()
        else
          if titleErrorMsg then @showTitleErrorMsg titleErrorMsg
          if descriptionErrorMsg then @showDescriptionErrorMsg descriptionErrorMsg
          @disableEditCorpusButton()

      title: title
      description: description

    hideTitleErrorMsg: -> @$(".title-error").first().stop().fadeOut()

    hideDescriptionErrorMsg: -> @$(".description-error").first().stop().fadeOut()

    getAn: (input) ->
      if input[0] in ['a', 'e', 'i', 'o', 'u'] then 'an' else 'a'

    submitWithEnter: (event) ->
      if event.which is 13
        @stopEvent event
        $editCorpusButton = @$('button.request-edit-corpus')
        disabled = $editCorpusButton.button 'option', 'disabled'
        if not disabled then $editCorpusButton.click()

    guify: ->

      @$('textarea[name=title]')
        .tooltip
          position:
            my: "right-85 center"
            at: "left center"
            collision: "flipfit"

      @$('textarea[name=description]')
        .tooltip
          position:
            my: "right-85 center"
            at: "left center"
            collision: "flipfit"

      @$('button.request-edit-corpus')
        .button()
        .tooltip
          position:
            my: 'right-85 center'
            at: 'left center'
            collision: 'flipfit'

      @$('.dative-edit-corpus-failed').hide()

    closeGUI: ->
      @visible = false
      @$el.slideUp()

    openGUI: ->
      @visible = true
      @$el.slideDown()

