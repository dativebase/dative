define [
  './input'
  './resource-as-row'
  './../models/resource'
  './../templates/resource-select-via-search-input'
  './../utils/globals'
], (InputView, ResourceAsRowView, ResourceModel,
  resourceSelectViaSearchInputTemplate, globals) ->

  # Resource Select Via Search Input View
  # -------------------------------------
  #
  # A view for selecting a particular resource (say, for a many-to-one
  # relation) by searching for it in a search input. This input should do some
  # "smart" search, i.e., try to understand what the user may be searching for.

  class ResourceSelectViaSearchInputView extends InputView

    # Change these attributes in subclasses.
    resourceName: 'resource'
    resourceModelClass: ResourceModel
    resourceAsRowViewClass: ResourceAsRowView

    template: resourceSelectViaSearchInputTemplate

    initialize: (context) ->
      super context
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural

    render: ->
      @context.resourceNameHuman = @utils.snake2regular @context.attribute
      super
      @buttonify()
      @tooltipify()
      @renderHeaderView()
      @searchResultsTable()
      #@prepResourceMediaView()
      @

    searchResultsTable: ->
      @searchResultsTableVisible = false
      @$('.resource-results-via-search-table-wrapper')
        .css 'border-color': @constructor.jQueryUIColors().defBo
      @searchResultsTableVisibility()

    resourceMediaView: null
    resourceMediaViewClass: null

    prepResourceMediaView: ->
      if @resourceMediaViewClass
        @resourceMediaView = new @resourceMediaViewClass(model: @model)
        $container = @$('.selected-resource-display-container').first()
        @resourceMediaView.setElement $container
        @resourceMediaView.render()
        @rendered @resourceMediaView
        @resourceMediaViewVisible = false
        $container.css 'border-color': @constructor.jQueryUIColors().defBo
        @resourceMediaViewVisibility()

    renderResourceMediaView: (model) ->
      if @resourceMediaViewClass
        if @resourceMediaView
          @resourceMediaView.close()
          @closed @resourceMediaView
        @resourceMediaView = new @resourceMediaViewClass(model: model)
        $container = @$('.selected-resource-display-container').first()
        @resourceMediaView.setElement $container
        @resourceMediaView.render()
        @rendered @resourceMediaView
        @resourceMediaViewVisible = true
        $container.css 'border-color': @constructor.jQueryUIColors().defBo
        @resourceMediaViewVisibility()

    tooltipify: ->
      @$('.dative-tooltip').tooltip()

    events:
      'click .perform-search': 'performSearch'

    listenToEvents: ->
      super
      @listenTo @model, 'searchSuccess', @searchSuccess
      @listenTo @model, 'searchStart', @searchStart
      @listenTo @model, 'searchEnd', @searchEnd
      @listenTo @model, 'searchFail', @searchFail

    itemsPerPage: 30

    resourceAsRowViews: []

    closeResourceAsRowViews: ->
      while @resourceAsRowViews.length
        view = @resourceAsRowViews.pop()
        view.close()
        @closed view

    getSearchResultsHeader: ->
      header = ['<div class="resource-as-row-row">']
      if @resourceAsRowViewClass::orderedAttributes
        iterator = @resourceAsRowViewClass::orderedAttributes
      else
        iterator = _.keys (new @resourceModelClass()).attributes
      for attribute in iterator
        header.push "<div class='resource-as-row-cell
          resource-as-row-attr-#{attribute}'
          >#{@utils.snake2regular attribute}</div>"
      header.push '</div>'
      header.join ''

    searchSuccess: (responseJSON) ->
      @showSearchResultsTableAnimateCheck()
      @closeResourceAsRowViews()
      @$('div.resource-results-via-search-table')
        .html @getSearchResultsRows(responseJSON)
        .scrollLeft 0

    renderHeaderView: ->
      headerObject = {}
      for attr in @resourceAsRowViewClass::orderedAttributes
        headerObject[attr] = @utils.snake2regular attr
      @headerModel = new @resourceModelClass headerObject
      @headerView = new @resourceAsRowViewClass
        model: @headerModel
        isHeaderRow: true
      @headerView.render()
      @rendered @headerView

    getSearchResultsRows: (responseJSON) ->
      fragment = document.createDocumentFragment()
      fragment.appendChild @headerView.el
      for modelObject in responseJSON.items
        resourceModel = new @resourceModelClass modelObject
        resourceAsRowView = new @resourceAsRowViewClass model: resourceModel
        @resourceAsRowViews.push resourceAsRowView
        resourceAsRowView.render()
        @rendered resourceAsRowView
        @listenToResourceAsRow resourceAsRowView
        fragment.appendChild resourceAsRowView.el
      fragment

    listenToResourceAsRow: (resourceAsRowView) ->
      @listenTo resourceAsRowView, 'selectMe', @selectResourceAsRowView

    selectResourceAsRowView: (resourceAsRowView) ->
      @model.set 'parent_file', resourceAsRowView.model.attributes
      @model.trigger 'setAttribute', 'start', 0
      @renderResourceMediaView resourceAsRowView.model
      @$('audio, video').on 'loadedmetadata', ((event) => @metadataLoaded event)

    onClose: ->
      @$('audio, video').off 'loadedmetadata'

    metadataLoaded: (event) ->
      @model.trigger 'setAttribute', 'end', event.currentTarget.duration

    searchFail: (errorMessage) ->
      Backbone.trigger 'fileSearchFail', errorMessage

    searchStart: ->
      @disableInterface()
      @spin()

    searchEnd: ->
      @enableInterface()
      @stopSpin()

    disableInterface: ->
      @$('button').button 'disable'
      @$('input').prop 'disabled', true

    enableInterface: ->
      @$('button').button 'enable'
      @$('input').prop 'disabled', false

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '130%'
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: -> @$('button.perform-search').first().spin @spinnerOptions()

    stopSpin: -> @$('button.perform-search').first().spin false

    getGlobalDataAttribute: -> "search#{@resourceNamePluralCapitalized}Data"

    performSearch: ->
      searchTerm = @$('[name=search-term]').val()
      if globals[@getGlobalDataAttribute()]
        paginator =
          page: 1
          items_per_page: @itemsPerPage
        query = @getSmartQuery searchTerm
        @model.search query, paginator
      else
        @listenToOnce @model,
          "getNew#{@resourceNameCapitalized}SearchDataSuccess",
          @getNewResourceSearchDataSuccess
        @listenToOnce @model, "getNew#{@resourceNameCapitalized}SearchDataFail",
          @getNewResourceSearchDataFail
        @model.getNewSearchData()

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that
    # TODO: consider fixing the following. You can't search files based on the
    # translations of the forms that they are associated to. This is a failing
    # of the OLD web service search interface. Adding this extra level of depth
    # would be useful here and elsewhere ...
    smartStringSearchableFileAttributes: [
      ['id']
      ['filename']
      ['name']
      ['url']
      ['MIME_type']
      ['description']
      ['forms', 'transcription']
      ['tags', 'name']
    ]

    # Returns `true` if `searchTerms` is an array containing a string that only
    # contains digits; here we assume the user is searching for a numeric id.
    isIdSearch: (searchTerms) ->
      searchTerms.length is 1 and searchTerms[0].match /^[0-9]+$/

    getAudioVideoMIMETypes: ->
      a = globals.applicationSettings.get 'allowedFileTypes'
      (t for t in a when t[...5] in ['audio', 'video'])

    isAudioVideoFilterExpression: ->
      [
        @resourceNameCapitalized
        'MIME_type'
        'in'
        @getAudioVideoMIMETypes()
      ]

    # Return a query object for intelligently searching over (OLD) file
    # resources, given the string `searchTerm`. Here we try to guess what the
    # user probably wants their search expression to do.
    getSmartQuery: (searchTerm) ->
      searchTerms = searchTerm.split /\s+/
      order_by = [@resourceNameCapitalized, 'id', 'desc']
      if @isIdSearch searchTerms
        filter = ['and', [
          @isAudioVideoFilterExpression(),
          [@resourceNameCapitalized, 'id', '=', parseInt(searchTerms[0])]]]
      else
        filter = @getGeneralFileSearch searchTerms
      order_by: order_by
      filter: filter

    # Return a search filter over File resources that returns all files such
    # that all of the search terms in `searchTerms` match (substring-wise) at
    # least one of the "string-searchable" file attributes listed in
    # `@smartStringSearchableFileAttributes`.
    getGeneralFileSearch: (searchTerms) ->
      filter = ['and']
      complement = [@isAudioVideoFilterExpression()]
      for searchTerm in searchTerms
        conjunct = ['or']
        subcomplement = []
        for attributeSet in @smartStringSearchableFileAttributes
          subfilter = [@resourceNameCapitalized]
          for attribute in attributeSet
            subfilter.push attribute
          subfilter.push 'like'
          subfilter.push "%#{searchTerm}%"
          subcomplement.push subfilter
        conjunct.push subcomplement
        complement.push conjunct
      filter.push complement
      filter

    getNewResourceSearchDataSuccess: (data) ->
      globals[@getGlobalDataAttribute()] = data
      @performSearch()

    getNewResourceSearchDataFail: (error) ->
      console.log "Sorry, we were not able to retrieve the data for creating a
        search over #{@resourceNamePlural}"

    # Search Results Table
    ############################################################################

    # Make the search results table visible, or not, depending on state.
    searchResultsTableVisibility: ->
      if @searchResultsTableVisible
        @showSearchResultsTable()
      else
        @hideSearchResultsTable()

    showSearchResultsTable: ->
      @searchResultsTableVisible = true
      @$('.resource-results-via-search-table-wrapper').first().show()

    hideSearchResultsTable: ->
      @searchResultsTableVisible = false
      @$('.resource-results-via-search-table-wrapper').first().hide()

    toggleSearchResultsTable: ->
      if @searchResultsTableVisible
        @hideSearchResultsTable()
      else
        @showSearchResultsTable()

    showSearchResultsTableAnimateCheck: ->
      if @$('.resource-results-via-search-table-wrapper').is ':hidden'
        @showSearchResultsTableAnimate()

    showSearchResultsTableAnimate: ->
      @searchResultsTableVisible = true
      @$('.resource-results-via-search-table-wrapper').first().slideDown()

    hideSearchResultsTableAnimate: ->
      @searchResultsTableVisible = false
      @$('.resource-results-via-search-table-wrapper').first().slideUp()

    toggleSearchResultsTableAnimate: ->
      if @searchResultsTableVisible
        @hideSearchResultsTableAnimate()
      else
        @showSearchResultsTableAnimate()


    # Resource Media View
    # NOTE: this presumes that the resource being searched here is files ...
    ############################################################################

    # Make the search results table visible, or not, depending on state.
    resourceMediaViewVisibility: ->
      if @resourceMediaViewVisible
        @showResourceMediaView()
      else
        @hideResourceMediaView()

    showResourceMediaView: ->
      @resourceMediaViewVisible = true
      @$('.selected-resource-display-container').first().show()

    hideResourceMediaView: ->
      @resourceMediaViewVisible = false
      @$('.selected-resource-display-container').first().hide()

    toggleResourceMediaView: ->
      if @resourceMediaViewVisible
        @hideResourceMediaView()
      else
        @showResourceMediaView()

    showResourceMediaViewAnimateCheck: ->
      if @$('.selected-resource-display-container').is ':hidden'
        @showResourceMediaViewAnimate()

    showResourceMediaViewAnimate: ->
      @resourceMediaViewVisible = true
      @$('.selected-resource-display-container').first().slideDown()

    hideResourceMediaViewAnimate: ->
      @resourceMediaViewVisible = false
      @$('.selected-resource-display-container').first().slideUp()

    toggleResourceMediaViewAnimate: ->
      if @resourceMediaViewVisible
        @hideResourceMediaViewAnimate()
      else
        @showResourceMediaViewAnimate()

