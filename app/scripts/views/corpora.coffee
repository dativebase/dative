define [
  'backbone'
  './base'
  './corpus'
  './../models/corpus'
  './../collections/corpora'
  './../templates/corpora'
  'perfectscrollbar'
], (Backbone, BaseView, CorpusView, CorpusModel, CorporaCollection,
  corporaTemplate) ->

  # Corpora View
  # ------------
  #
  # Displays a list of FieldDB corpora.

  class CorporaView extends BaseView

    tagName: 'div'
    template: corporaTemplate

    initialize: (options) ->
      @collection = new CorporaCollection()
      @applicationSettings = options.applicationSettings
      @addCorpusModelsToCollection()
      @corpusViews = []
      @collection.each (corpus) =>
        newCorpusView = new CorpusView
          model: corpus
          applicationSettings: @applicationSettings.toJSON()
        corpus.fetch()
        @corpusViews.push newCorpusView

    addCorpusModelsToCollection: () ->
      corpusMetadataArray = @applicationSettings.get('loggedInUser').corpuses
      for corpusMetadata in corpusMetadataArray
        corpusModel = new CorpusModel
          applicationSettings: @applicationSettings
          metadata: corpusMetadata
        @collection.add corpusModel

    listenToEvents: ->
      @delegateEvents()

    events:
      'keydown button.add-corpus': 'addCorpusKeys'
      'click button.add-corpus': 'addCorpus'
      'keydown button.save-corpora': 'saveCorporaKeys'
      'click button.save-corpora': 'saveCorpora'

    render: ->
      @$el.html @template()
      @matchHeights()
      @$pageBody = @$('div#dative-page-body').first()
      @guify()
      container = document.createDocumentFragment()
      for corpusView in @corpusViews
        container.appendChild corpusView.render().el
        @rendered corpusView
      @$pageBody.append container
      @listenToEvents()
      @$pageBody.perfectScrollbar()
      @

    setCollectionFromGUI: ->
      updatedCorpusModels = []
      for corpusView in @corpusViews
        corpusView.setModelFromGUI()
        updatedCorpusModels.push corpusView.model
      @collection.add updatedCorpusModels

    addCorpus: (event) ->
      if event
        event.preventDefault()
        event.stopPropagation()
      corpusModel = new CorpusModel()
      @collection.unshift corpusModel
      corpusView = new CorpusView model: corpusModel
      @corpusViews.unshift corpusView
      corpusView.render().$el.prependTo(@$pageBody).hide().slideDown('slow')
      @rendered corpusView

    guify: ->

      @$('button').button().attr('tabindex', 0)

      @$('button.add-corpus')
        .button
          icons: {primary: 'ui-icon-plusthick'}
          text: false
        .tooltip()

      @$('button.save-corpora')
        .button
          icons: {primary: 'ui-icon-disk'}
          text: false
        .tooltip()

    _rememberTarget: (event) ->
      try
        @$('.dative-input-display').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    addCorpusKeys: (event) ->
      @_rememberTarget event
      if event.which is 13 # Enter
        @stopEvent event
        @addCorpus()

    saveCorporaKeys: (event) ->
      @_rememberTarget event
      if event.which is 13 # Enter
        @stopEvent event
        @saveCorpora()

    saveCorpora: ->
      console.log 'you want to save these corpora to the server'

