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
      @stopListening()
      @undelegateEvents()
      @delegateEvents()


    events:
      'keydown button.add-corpus': 'addCorpusKeys'
      'click button.add-corpus': 'addCorpus'

      'keydown button.expand-all-corpora': 'expandAllCorporaKeys'
      'click button.expand-all-corpora': 'expandAllCorpora'

      'keydown button.collapse-all-corpora': 'collapseAllCorporaKeys'
      'click button.collapse-all-corpora': 'collapseAllCorpora'

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
          disabled: true # TODO: implement the addCorpus action!
        .tooltip()

      @$('button.expand-all-corpora')
        .button
          icons: {primary: 'ui-icon-arrowthickstop-1-s'}
          text: false
        .tooltip()

      @$('button.collapse-all-corpora')
        .button
          icons: {primary: 'ui-icon-arrowthickstop-1-n'}
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

    expandAllCorporaKeys: (event) ->
      @_rememberTarget event
      if event.which in [13, 32]
        @stopEvent event
        @expandAllCorpora()

    expandAllCorpora: (event) ->
      for corpusView in @corpusViews
        corpusView.fetchThenOpen()

    collapseAllCorporaKeys: (event) ->
      @_rememberTarget event
      if event.which in [13, 32]
        @stopEvent event
        @collapseAllCorpora()

    collapseAllCorpora: (event) ->
      for corpusView in @corpusViews
        corpusView.closeBody()

