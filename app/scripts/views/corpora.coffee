define [
  'backbone'
  './base'
  './corpus'
  './create-corpus'
  './../models/corpus'
  './../collections/corpora'
  './../utils/globals'
  './../templates/corpora'
], (Backbone, BaseView, CorpusView, CreateCorpusView, CorpusModel, CorporaCollection,
  globals, corporaTemplate) ->

  # Corpora View
  # ------------
  #
  # Displays a list of FieldDB corpora.

  class CorporaView extends BaseView

    tagName: 'div'
    template: corporaTemplate

    initialize: (options) ->
      @focusedElementIndex = null
      @applicationSettings = options.applicationSettings
      @activeFieldDBCorpus = options.activeFieldDBCorpus
      @collection = new CorporaCollection()
      @collection.applicationSettings = @applicationSettings
      # @listenTo @applicationSettings.get('fieldDBApplication').authentication.user.corpora, 'change', @addCorpusModelsToCollection
      @exponentialBackoffLoadCorpora = 2000
      setTimeout((=> @addCorpusModelsToCollection()), @exponentialBackoffLoadCorpora)

      @corpusViews = []
      @createCorpusView = new CreateCorpusView()
      @getAndFetchCorpusViews()

    addCorpusModelsToCollection: ->
      # WARN: I'm ignoring `public-firstcorpus` and `llinglama-communitycorpus' for now
      if not @applicationSettings.get('fieldDBApplication') or not @applicationSettings.get('fieldDBApplication').authentication or not @applicationSettings.get('fieldDBApplication').authentication.user or not @applicationSettings.get('fieldDBApplication').authentication.user.corpora or not @applicationSettings.get('fieldDBApplication').authentication.user.corpora.collection
        @exponentialBackoffLoadCorpora = @exponentialBackoffLoadCorpora * 2
        console.log 'Waiting another ' + @exponentialBackoffLoadCorpora + ' seconds for the user to become available' 
        setTimeout((=> @addCorpusModelsToCollection()), @exponentialBackoffLoadCorpora)
        return
      for corpusConnection in @applicationSettings.get('fieldDBApplication').authentication.user.corpora.collection
        if (corpusConnection.dbname == 'public-firstcorpus' || corpusConnection.dbname == 'llinglama-communitycorpus')
          continue
        # corpusConnection.applicationSettings = @applicationSettings
        corpusModel = new CorpusModel({connection: corpusConnection} )
        @collection.add corpusModel
        newCorpusView = new CorpusView
          model: corpusModel
          applicationSettings: @applicationSettings.toJSON()
          activeFieldDBCorpus: @activeFieldDBCorpus
        @corpusViews.push newCorpusView
        @render()

    getAndFetchCorpusViews: ->
      @collection.each (corpus) =>
        newCorpusView = new CorpusView
          model: corpus
          applicationSettings: @applicationSettings.toJSON()
          activeFieldDBCorpus: @activeFieldDBCorpus
        # corpus.fetch()
        @corpusViews.push newCorpusView

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @createCorpusView, 'request:createCorpus', @issueCreateCorpusRequest
      @listenTo Backbone, 'newCorpusSuccess', @newCorpusAddedToCollection

    newCorpusAddedToCollection: (newCorpusName) ->
      @prependNewCorpusViewToCorpusViews()
      @prependNewCorpusViewToDOM()

    prependNewCorpusViewToCorpusViews: ->
      newCorpusModel = @collection.at 0
      newCorpusView = new CorpusView
        model: newCorpusModel
        applicationSettings: @applicationSettings.toJSON()
        activeFieldDBCorpus: @activeFieldDBCorpus
      @corpusViews.unshift newCorpusView

    prependNewCorpusViewToDOM: ->
      @corpusViews[0].render().$el.prependTo(@$('div.corpora-list'))
        .hide().slideDown('slow')
      @rendered @corpusViews[0]

    issueCreateCorpusRequest: (corpusName) ->
      @collection.newCorpus corpusName

    events:
      'keydown button.create-corpus': 'toggleCreateCorpusKeys'
      'click button.create-corpus': 'toggleCreateCorpus'
      'keydown button.expand-all-corpora': 'expandAllCorporaKeys'
      'click button.expand-all-corpora': 'expandAllCorpora'
      'keydown button.collapse-all-corpora': 'collapseAllCorporaKeys'
      'click button.collapse-all-corpora': 'collapseAllCorpora'
      'focus button, input, .ui-selectmenu-button': 'rememberFocusedElement'
      'focus input': 'scrollToFocusedInput'
      'focus button': 'scrollToFocusedInput'

    render: (taskId) ->
      @$el.html @template()
      @matchHeights()
      @guify()
      @renderCorpusViews()
      @renderCreateCorpusView()
      @listenToEvents()
      if @createCorpusView.visible
        @createCorpusView.show()
      else
        @createCorpusView.hide()
      @$('div#dative-page-body').first().scroll => @closeAllTooltips()
      @setFocus()
      @fixRoundedBorders()
      Backbone.trigger 'longTask:deregister', taskId
      @

    setFocus: ->
      if @focusedElementIndex
        @focusLastFocusedElement()
      else
        @focusFirstButton()

    focusFirstButton: ->
      @$('button.ui-button').first().focus()

    setCreateCorpusButtonState: ->
      contentSuffix = 'form for creating a new corpus'
      if @createCorpusView.visible
        @$('button.create-corpus').tooltip
          content: "show #{contentSuffix}"
      else
        @$('button.create-corpus').tooltip
          content: "hide #{contentSuffix}"

    toggleCreateCorpus: (event) ->
      if event then @stopEvent event
      @setCreateCorpusButtonState()
      if @createCorpusView.visible
        @createCorpusView.closeGUI()
      else
        @createCorpusView.openGUI()
        @createCorpusView.focusNameInput()

    toggleCreateCorpusKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @toggleCreateCorpus event

    renderCreateCorpusView: ->
      @$('div.create-corpus-widget-container').html @createCorpusView.render().$el
      @rendered @createCorpusView

    renderCorpusViews: ->
      container = document.createDocumentFragment()
      for corpusView in @corpusViews
        container.appendChild corpusView.render().el
        @rendered corpusView
      @$('div.corpora-list').append container

    # The special `onClose` event is called by `close` in base.coffee upon close
    onClose: ->
      @$('div#dative-page-body').first().unbind 'scroll'

    setCollectionFromGUI: ->
      updatedCorpusModels = []
      for corpusView in @corpusViews
        corpusView.setModelFromGUI()
        updatedCorpusModels.push corpusView.model
      @collection.add updatedCorpusModels

    guify: ->

      @$('button').button().attr('tabindex', 0)

      @$('button.create-corpus')
        .button()
        .tooltip
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.expand-all-corpora')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

      @$('button.collapse-all-corpora')
        .button()
        .tooltip
          position:
            my: "right-80 center"
            at: "left center"
            collision: "flipfit"

    expandAllCorporaKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @expandAllCorpora()

    expandAllCorpora: (event) ->
      if event then @stopEvent event
      for corpusView in @corpusViews
        corpusView.shouldFocusToggleButtonUponOpen = false
        corpusView.fetchThenOpen()

    collapseAllCorporaKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @collapseAllCorpora()

    collapseAllCorpora: (event) ->
      if event then @stopEvent event
      for corpusView in @corpusViews
        corpusView.closeBody()

