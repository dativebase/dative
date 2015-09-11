define [
  './base'
  './form'
  './../models/form'
  './../models/search'
  './../collections/forms'
  './../templates/smart-query-preview'
], (BaseView, FormView, FormModel, SearchModel, FormsCollection,
  smartQueryPreviewTemplate) ->

  class SmartQueryPreviewView extends BaseView

    template: smartQueryPreviewTemplate
    tagName: 'div'
    className: 'smart-query-preview-container'

    targetResourceViewClass: FormView
    targetResourceModelClass: FormModel
    targetResourceCollectionClass: FormsCollection
    searchModelClass: SearchModel

    initialize: (options) ->
      @searchInitiated = false
      @description = @model._mySmartQuery.description
      @matchCount = null
      @matchExampleView = null
      @matchExampleRendered = false
      @listenToEvents()

    render: ->
      @listenToEvents()
      context =
        description: @description
        matchCount: @utils.integerWithCommas @matchCount
      @$el.html @template(context)
      if @matchCount is 0
        @$('button').button disabled: true
      else
        @$('button').button()
      @$('.dative-tooltip').tooltip()
      @$('.smart-query-preview-example-match-container').first().hide()
      @

    listenToEvents: ->
      super
      @listenTo @model, "searchStart", @searchStart
      @listenTo @model, "searchEnd", @searchEnd
      @listenTo @model, "searchSuccess", @searchSuccess
      @listenTo @model, "searchFail", @searchFail

    events:
      'click .smart-query-preview-view-example': 'showMatchExample'
      'click .smart-query-preview-browse': 'requestBrowse'

    showMatchExample: ->
      $container = @$('.smart-query-preview-example-match-container').first()
      if not @matchExampleRendered
        $container.html @matchExampleView.render().el
        @rendered @matchExampleView
        @matchExampleRendered = true
      if $container.is ':visible'
        @$('button.smart-query-preview-view-example')
          .tooltip content: 'See an example of a resource that matches this query'
        @$('.smart-query-preview-example-match-container').slideUp()
      else
        @$('button.smart-query-preview-view-example')
          .tooltip content: 'Hide the example'
        @$('.smart-query-preview-example-match-container').slideDown()

    requestBrowse: -> @trigger 'browseMe', @model

    searchSuccess: (responseJSON) ->
      @matchCount = responseJSON.paginator.count
      @trigger 'countRetrieved', @
      if @matchCount > 0
        @$('button').button 'enable'
        searchModel = new @searchModelClass(search: @model._mySmartQuery.query)
        searchPatternsObject = searchModel.getPatternsObject()
        targetCollection = new @targetResourceCollectionClass()
        matchExampleModel = new @targetResourceModelClass(
          responseJSON.items[0],
          {collection: targetCollection})
        @matchExampleView =
          new @targetResourceViewClass
            model: matchExampleModel
            expanded: true
            searchPatternsObject: searchPatternsObject
      else
        @$('button').button 'disable'
        @matchExampleView = null
      noun = if @matchCount is 1 then 'match' else 'matches'
      @$('.smart-query-preview-match-count')
        .text "#{@utils.integerWithCommas @matchCount} #{noun}"

    searchFail: (errorMessage, targetResourceModel) ->
      @matchCount = 0
      @trigger 'countRetrieved', @
      @matchExampleView = null
      @$('button').button 'disable'
      @$('.smart-query-preview-match-count').text '0 matches'

    searchStart: ->
      @searchInitiated = true
      @$('.smart-query-preview-match-count').text 'searching'
      @spin()

    searchEnd: ->
      @trigger 'searchPerformed'
      @stopSpin()

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '-10%'
      #options.color = @constructor.jQueryUIColors().errCo
      options

    spin: -> @$('.smart-query-preview-match-count').first().spin @spinnerOptions()

    stopSpin: -> @$('.smart-query-preview-match-count').first().spin false

