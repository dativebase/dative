define [
  'backbone'
  './base'
  './corpus'
  './create-corpus'
  './../models/corpus'
  './../collections/corpora'
  './../templates/corpora'
  'perfectscrollbar'
], (Backbone, BaseView, CorpusView, CreateCorpusView, CorpusModel, CorporaCollection,
  corporaTemplate) ->

  # Corpora View
  # ------------
  #
  # Displays a list of FieldDB corpora.

  class CorporaView extends BaseView

    tagName: 'div'
    template: corporaTemplate

    initialize: (options) ->
      @applicationSettings = options.applicationSettings
      @collection = new CorporaCollection()
      @collection.applicationSettings = @applicationSettings
      @addCorpusModelsToCollection()
      @corpusViews = []
      @createCorpusView = new CreateCorpusView()
      @getAndFetchCorpusViews()

    addCorpusModelsToCollection: () ->
      corpusMetadataArray = @applicationSettings.get('loggedInUser').corpuses
      for corpusMetadata in corpusMetadataArray
        corpusModel = new CorpusModel
          applicationSettings: @applicationSettings
          metadata: corpusMetadata
        @collection.add corpusModel

    getAndFetchCorpusViews: ->
      @collection.each (corpus) =>
        newCorpusView = new CorpusView
          model: corpus
          applicationSettings: @applicationSettings.toJSON()
        corpus.fetch()
        @corpusViews.push newCorpusView

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @createCorpusView, 'request:createCorpus', @createCorpus

    createCorpus: (corpusName) ->
      console.log "You want the corpora view to request creation of the corpus #{corpusName}"

    events:
      'keydown button.create-corpus': 'toggleCreateCorpusKeys'
      'click button.create-corpus': 'toggleCreateCorpus'

      'keydown button.expand-all-corpora': 'expandAllCorporaKeys'
      'click button.expand-all-corpora': 'expandAllCorpora'

      'keydown button.collapse-all-corpora': 'collapseAllCorporaKeys'
      'click button.collapse-all-corpora': 'collapseAllCorpora'

    render: ->
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
      @perfectScrollbar()
      @

    setCreateCorpusButtonState: ->
      contentSuffix = 'form for creating a new corpus'
      if @createCorpusView.visible
        @$('button.create-corpus').tooltip
          content: "show #{contentSuffix}"
      else
        @$('button.create-corpus').tooltip
          content: "hide #{contentSuffix}"

    toggleCreateCorpus: (event) ->
      console.log 'in toggleCreateCorpus'
      if event then @stopEvent event
      @setCreateCorpusButtonState()
      if @createCorpusView.visible
        @createCorpusView.closeGUI()
      else
        @createCorpusView.openGUI()

    toggleCreateCorpusKeys: (event) ->
      @_rememberTarget event
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

    perfectScrollbar: -> @$('div#dative-page-body').first().perfectScrollbar()

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
        .tooltip()

      @$('button.expand-all-corpora')
        .button()
        .tooltip()

      @$('button.collapse-all-corpora')
        .button()
        .tooltip()

    _rememberTarget: (event) ->
      try
        @$('.dative-input-display').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    expandAllCorporaKeys: (event) ->
      @_rememberTarget event
      if event.which in [13, 32]
        @stopEvent event
        @expandAllCorpora()

    expandAllCorpora: (event) ->
      if event then @stopEvent event
      for corpusView in @corpusViews
        corpusView.fetchThenOpen()

    collapseAllCorporaKeys: (event) ->
      @_rememberTarget event
      if event.which in [13, 32]
        @stopEvent event
        @collapseAllCorpora()

    collapseAllCorpora: (event) ->
      if event then @stopEvent event
      for corpusView in @corpusViews
        corpusView.closeBody()

