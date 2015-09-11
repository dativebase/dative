define [
  './base'
  './resource'
  './search-add-widget'
  './search-field'
  './smart-query-preview'
  './../models/search'
  './../models/form'
  './../collections/searches'
  './../templates/search-widget'
  './../utils/globals'
], (BaseView, ResourceView, SearchAddWidgetView, SearchFieldView,
  SmartQueryPreviewView, SearchModel, FormModel, SearchesCollection,
  searchWidgetTemplate, globals) ->


  class MySearchAddWidgetView extends SearchAddWidgetView

    # Return the array of resource names that this search add widget needs in
    # order for a search over the target resource to be created. Note that this
    # is an override of the super-class's method. This is because here
    # `@resourceName` alone (i.e., "search") is insufficient: we need to know
    # also what the target resource is, i.e., what we are searching over.
    relatedResourcesNeeded: ->
      key = "#{@targetResourceName}_search"
      if key of globals.relatedResources
        globals.relatedResources[key]
      else
        []


  # Search Widget
  # -------------
  #
  # A view that contains a SearchFieldView and buttons for
  # - performing the search (i.e., browsing the results),
  # - counting the search results, and
  # - saving the search.

  class SearchFieldViewNoLabel extends SearchFieldView

    showLabel: false


  class SearchWidgetView extends ResourceView

    # Change the following  attributes in sub-classes. These indicate which
    # resource is being searched.
    targetResourceName: 'form'
    targetModelClass: FormModel
    searchModelClass: SearchModel
    searchFieldViewClass: SearchFieldViewNoLabel

    resourceName: 'search'

    # TODO: these delimiters should be based on delimiters in app settings
    # since they can be corpus/database/language-specific.
    delims: ['-', '=']

    tagName: 'div'
    className: 'dative-search-widget dative-shadowed-widget
      dative-widget-center ui-widget ui-widget-content ui-corner-all'
    template: searchWidgetTemplate

    events:
      'click .search-button': 'search'
      'click .count-button': 'count'
      'click .save-button': 'save'
      'click .hide-search-widget': 'hideMe'
      'click .help': 'openHelp'
      'click .browse-return': 'browseReturn'
      'click .reset-query': 'resetQuery'
      'click button.advanced-search': 'exposeAdvancedSearchInterface'
      'click button.smart-search': 'exposeSmartSearchInterface'
      'keydown textarea.smart-search-input': 'ctrlEnter'
      'keydown': 'keyboardShortcuts'

    exposeAdvancedSearchInterface: ->
      @searchType = 'advanced'
      @searchTypeState()
      @$('textarea.value').first().focus()

    exposeSmartSearchInterface: ->
      @searchType = 'smart'
      @searchTypeState()
      @$('.smart-search-input').first().focus()

    resetQuery: (event) ->
      @model = new @searchModelClass()
      @render()

    ctrlEnter: (event) ->
      switch event.which
        when 13
          @stopEvent event
          @search()

    keyboardShortcuts: (event) ->
      event.stopPropagation()
      switch event.which
        when 27 then @hideMe()

    # Browse the results of the search in the search widget. Here we trigger a
    # Backbone event that the master `AppView` instance listens for and then
    # refreshes the relevant resources browse view.
    search: ->
      if @searchType is 'advanced'
        Backbone.trigger(
          "request:#{@targetResourceNamePlural}BrowseSearchResults",
          search: @model.get('search'))
      else
        smartSearchTerm = @$('textarea.smart-search-input').first().val().trim()
        @smartSearch smartSearchTerm
        @model.set 'smart_search', smartSearchTerm

    string2hash: (string) ->
      hash = 0
      if string.length is 0 then return hash
      for chr in string
        hash  = ((hash << 5) - hash) + chr
        hash |= 0 # Convert to 32bit integer
      hash

    # Perform a "smart" search based on `searchTerm`. Here we do some
    # simple pattern matching on `searchTerm` and use its properties to
    # generate a series of distinct searches, within a fixed limit. We then
    # issue several search requests to the server and ask for one
    # representative example. Then we present this information to the user
    # and ask the user to select a search based on it.
    smartSearch: (searchTerm) ->
      smartQueries = @getSmartQueries searchTerm
      @closeSmartQueryPreviewViews()
      for smartQuery in smartQueries
        targetResourceModel = new @targetModelClass()
        targetResourceModel._mySmartQuery = smartQuery
        smartQueryPreviewView = new SmartQueryPreviewView
          model: targetResourceModel
        @smartQueryPreviewViews.push smartQueryPreviewView
      @listenToSmartQueryPreviewViews()
      @renderSmartQueryPreviewViews()
      @triggerSmartQuerySearches()

    listenToSmartQueryPreviewViews: ->
      for view in @smartQueryPreviewViews
        @listenTo view, 'browseMe', @browseQueryFromPreviewView
        @listenTo view, 'searchPerformed', @triggerNextSmartQuerySearch
        @listenTo view, 'countRetrieved', @smartQueryResultsCounted

    # Every time a smart query preview view tells us that its matches have been
    # counted, we check if all of our preview views have had their matches
    # counted. If so, then we re-render them ordered according to matches
    # (fewest matches to most matches but with ones with 0 matches at the
    # bottom).
    smartQueryResultsCounted: (smartQueryPreviewView) ->
      allResultsCounted = true
      for view in @smartQueryPreviewViews
        if not _.isNumber(view.matchCount) then allResultsCounted = false
      if allResultsCounted
        reorderedSmartQueryPreviewViews = []
        smartQueryPreviewViewsWithNoMatches = []
        for view in @smartQueryPreviewViews
          if view.matchCount is 0
            smartQueryPreviewViewsWithNoMatches.push view
          else
            reorderedSmartQueryPreviewViews.push view
            reorderedSmartQueryPreviewViews =
              _.sortBy reorderedSmartQueryPreviewViews, 'matchCount'
          reorderedSmartQueryPreviewViews =
            reorderedSmartQueryPreviewViews.concat(
              smartQueryPreviewViewsWithNoMatches)
          @closeSmartQueryPreviewViews()
          @smartQueryPreviewViews = reorderedSmartQueryPreviewViews
          @renderSmartQueryPreviewViews()

    # This method is called when the user clicks the "Browse" button on a
    # particular query preview view.
    browseQueryFromPreviewView: (targetModel) ->
      @model.set 'search', targetModel._mySmartQuery.query
      Backbone.trigger(
        "request:#{@targetResourceNamePlural}BrowseSearchResults",
        search: @model.get('search')
        smartSearch: @model.get('smart_search'))

    synchronousSearchCountMax: 4

    # Trigger SEARCH requests for as subset of of our smart queries. We just
    # ask for one match, so we don't needlessly burden the server. This is a
    # basic queue: we only initiate the first `@synchronousSearchCountMax`
    # queries and we request searches based on the remaining ones as pending
    # requests terminate.
    triggerSmartQuerySearches: ->
      count = 0
      for view in @smartQueryPreviewViews
        if count >= @synchronousSearchCountMax then break
        view.model.search(
          view.model._mySmartQuery.query,
          {page: 1, items_per_page: 1})
        count += 1

    # Issue a SEARCH request for the next smart query in line.
    triggerNextSmartQuerySearch: ->
      remaining = (q for q in @smartQueryPreviewViews \
        when not q.searchInitiated)
      if remaining.length > 0
        view = remaining[0]
        view.model.search(
          view.model._mySmartQuery.query,
          {page: 1, items_per_page: 1})

    # Cleanly close all of our existing smart query preview views.
    closeSmartQueryPreviewViews: ->
      for view in @smartQueryPreviewViews
        view.close()
        @closed view
      @smartQueryPreviewViews = []

    # Render our smart query preview views.
    renderSmartQueryPreviewViews: ->
      $container = @$('div.smart-search-preview-container').first()
      for view in @smartQueryPreviewViews
        $container.append view.render().el
        @rendered view

    # Initiate a search request in order to count how many results the
    # currently specified search would return and display that count in a
    # notifier.
    count: ->
      paginator = {page: 1, items_per_page: 1}
      @listenToOnce @targetModel, 'searchSuccess', @displayCount
      @targetModel.search @model.get('search'), paginator

    # Trigger the notifier into displaying the search results count.
    displayCount: (searchResponse) ->
      count = searchResponse.paginator.count
      Backbone.trigger 'resourceCountSuccess', @targetResourceName, count

    # Save the search that is currently held in the search widget.
    save: ->
      searchesCollection = new SearchesCollection()
      @newSearchModel =
        new SearchModel(@model.attributes, {collection: searchesCollection})
      Backbone.trigger 'showResourceModelInDialog', @newSearchModel, 'search'

    # Trigger an event so that the superview `ResourcesView` instance will take
    # us back to browsing all resources.
    browseReturn: -> @trigger 'browseReturn'

    hideMe: ->
      @trigger 'hideMe'

    # Tell the Help dialog to open itself and search for "searching `@targetResourceNamePlural`" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "searching #{@targetResourceNamePlural}"
        scrollToIndex: 1
      )

    initialize: ->
      @searchType = 'advanced'
      @smartQueryTargetResourceModels = []
      @smartQueryPreviewViews = []
      @getNames()
      @mixinSearchAddWidgetView()
      @model = new @searchModelClass()
      @targetModel = new @targetModelClass()
      @listenToEvents()

    getNames: ->
      @targetResourceNameCapitalized = @utils.capitalize @targetResourceName
      @targetResourceNamePlural = @utils.pluralize @targetResourceName
      @targetResourceNamePluralCapitalized =
        @utils.capitalize @targetResourceNamePlural

    # Appropriate a subset of the methods of `SearchAddWidgetView`.
    mixinSearchAddWidgetView: ->
      methodsWeWant = [
        'relatedResourcesNeeded'
        'checkForRelatedResourceData'
        'getNewResourceData'
        'getNewResourceDataStart'
        'getNewResourceDataEnd'
        'getNewResourceDataSuccess'
        'getNewResourceDataFail'
        'getOptions'
      ]
      for method in methodsWeWant
        @[method] = MySearchAddWidgetView::[method]

    # We may have `SearchWidgetView`s over various resources (e.g., forms,
    # files, etc.). Therefore, we need a different global attribute for each
    # type of search widget so that we can know which attributes to search over
    # for forms and which for files and not get them mixed up. This overwrites a
    # method in `ResourceAddWidgetView`.
    getGlobalDataAttribute: ->
      "#{@resourceName}Over#{@targetResourceNamePluralCapitalized}Data"

    render: ->
      if @checkForRelatedResourceData() is 'exit' then return
      @searchFieldView = @getSearchFieldView()
      @html()
      @guify()
      @renderSearchFieldView()
      @listenToEvents()
      @searchTypeState()
      @

    searchTypeState: ->
      if @searchType is 'advanced'
        @disableAdvancedSearchButton()
        @enableSmartSearchButton()
        @hideSmartSearchInterface()
        @showAdvancedSearchInterface()
        @showCountButton()
        @showSaveButton()
        @$('.search-type-header').text 'Advanced'
      else
        @enableAdvancedSearchButton()
        @disableSmartSearchButton()
        @showSmartSearchInterface()
        @hideAdvancedSearchInterface()
        @hideCountButton()
        @hideSaveButton()
        @$('.search-type-header').text 'Smart'

    showCountButton: -> @$('button.count-button').show()

    hideCountButton: -> @$('button.count-button').hide()

    showSaveButton: -> @$('button.save-button').show()

    hideSaveButton: -> @$('button.save-button').hide()

    showSmartSearchInterface: ->
      @$('div.smart-search-interface').show()

    hideSmartSearchInterface: ->
      @$('div.smart-search-interface').hide()

    showAdvancedSearchInterface: ->
      @$('div.advanced-search-interface').show()

    hideAdvancedSearchInterface: ->
      @$('div.advanced-search-interface').hide()

    enableAdvancedSearchButton: ->
      @$('.advanced-search').button 'enable'

    disableAdvancedSearchButton: ->
      @$('.advanced-search').button 'disable'

    enableSmartSearchButton: ->
      @$('.smart-search').button 'enable'

    disableSmartSearchButton: ->
      @$('.smart-search').button 'disable'


    # TODO: can this safely be deleted?
    x: ->
      if not @weHaveNewResourceData()
        @model.getNewResourceData() # Success in this request will call `@render()`
        return

    getSearchFieldView: ->
      new @searchFieldViewClass
        resource: @targetResourceNamePlural
        attribute: 'search'
        model: @model
        options: @getOptions()

    listenToEvents: ->
      # Events specific to an OLD backend and the request for the data needed
      # to create a resource.
      @listenTo @model, "getNewSearchDataStart",
        @getNewResourceDataStart
      @listenTo @model, "getNewSearchDataEnd",
        @getNewResourceDataEnd
      @listenTo @model, "getNewSearchDataSuccess",
        @getNewResourceDataSuccess
      @listenTo @model, "getNewSearchDataFail",
        @getNewResourceDataFail
      if @searchFieldView
        @listenTo @searchFieldView, 'search', @search

    renderSearchFieldView: ->
      @$('ul.advanced-search-interface').append @searchFieldView.render().el
      @rendered @searchFieldView

    html: ->
      context =
        targetResourceNamePlural: @targetResourceNamePlural
        targetResourceNamePluralCapitalized:
          @targetResourceNamePluralCapitalized
        searchType: @searchType
        searchTypeCapitalized: @utils.capitalize @searchType
        smartSearch: @model.get 'smart_search'
      @$el.html @template(context)

    guify: ->
      @buttonify()
      @tooltipify()
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo
      @$('textarea.smart-search-input')
        .css "border-color", @constructor.jQueryUIColors().defBo

    buttonify: ->
      @$('.dative-widget-header button').button()
      @$('.button-only-fieldset button').button()

      # Make all of righthand-side buttons into jQuery buttons and set the
      # position of their tooltips programmatically based on their
      # position/index.
      @$(@$('.button-container-right button').get().reverse())
        .each (index, element) =>
          leftOffset = (index * 35) + 10
          @$(element)
            .button()
            .tooltip
              position:
                my: "left+#{leftOffset} center"
                at: "right center"
                collision: "flipfit"

    # Make the `title` attributes of the inputs/controls into jQueryUI tooltips.
    tooltipify: ->
      @$('.dative-widget-header .hide-search-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-widget-header .advanced-search.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-55')
      @$('.dative-widget-header .smart-search.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-170')
      @$('ul.button-only-fieldset button.dative-tooltip').tooltip()
      @$('textarea.smart-search-input')
        .tooltip position: @tooltipPositionLeft('-20')

    ############################################################################
    # Logic for building the "smart" query/ies
    ############################################################################

    # Note: much of this is duplication from
    # resource-select-via-search-input.coffee and should be DRY-ed.

    # Returns `true` if `searchTerms` is an array containing a string that only
    # contains digits; here we assume the user is searching for a numeric id.
    isIdSearch: (searchTerms) ->
      searchTerms.length is 1 and searchTerms[0].match /^[0-9]+$/

    # Return an array of one or more query objects for intelligently searching
    # over (OLD) resources of the targeted type, given the string `searchTerm`.
    # Here we try to guess what the user probably wants their search expression
    # to do.
    getSmartQueries: (searchTerm) ->
      searchTerms = searchTerm.split /\s+/
      order_by = [@targetResourceNameCapitalized, 'id', 'desc']
      if @isIdSearch searchTerms
        filter = @getIdSearchFilter searchTerms
        description = "All #{@targetResourceNamePlural} that have
          “#{@highL}#{searchTerms[0]}#{@highR}” as their
          #{@highL}id#{@highR} value."
        queries = [
          query: {order_by: order_by, filter: filter}
          description: description
          rank: 10
        ]

      else
        filters = @getSmartFilters searchTerm, searchTerms
        queries = []
        for filter in filters
          query =
            query: {order_by: order_by, filter: filter.filter}
            description: filter.description
            rank: filter.rank
          queries.push query
      _.sortBy(queries, 'rank').reverse()

    getIdSearchFilter: (searchTerms) ->
      [@targetResourceNameCapitalized, 'id', '=', parseInt(searchTerms[0])]

    # Return an array of "smart filters". Each smart filter is an object with a
    # `description` and a `filter` attribute. The filter is the OLD-style
    # filter expression (an array), while the description is a string that
    # describes what the filter matches.
    getSmartFilters: (searchTerm, searchTerms) ->
      if searchTerms.length is 1
        filters = [
          @getSearchTermIsAMorphemeFilter searchTerm
          @getSearchTermIsAWordFilter searchTerm
          @getSearchTermEqualsAnyLikelyAttributeFilter searchTerm
          @getSearchTermSubstringMatchesAnyLikelyAttributeFilter searchTerm
        ]
      else
        filters = [
          @getSearchTermIsAMorphemeFilter searchTerm
          @getSearchTermIsAWordFilter searchTerm
          @getSearchTermEqualsAnyLikelyAttributeFilter searchTerm
          @getSearchTermSubstringMatchesAnyLikelyAttributeFilter searchTerm
          @getAllSearchTermsAreMorphemesFilter searchTerms
          @getAllSearchTermsAreWordsFilter searchTerms
          @getAllSearchTermsEqualAnyLikelyAttributeFilter searchTerms
          @getAllSearchTermsSubstringMatchAnyLikelyAttributeFilter searchTerms
        ]
      (f for f in filters when f isnt null)

    # Return a string that expresses a coordination of all of the tokens in
    # `array`.
    coordinate: (array, coordinator='and') ->
      if array.length > 1
        "“#{("#{@highL}#{x}#{@highR}" for x in array[...-1]).join '”, “'}”
          #{coordinator} “#{@highL}#{array[array.length - 1]}#{@highR}”"
      else if array.length is 1
        "“#{@highL}#{array[0]}#{@highR}”"
      else
        ''

    highL: "<span class='dative-state-highlight'>"
    highR: "</span>"

    ############################################################################
    # Methods that return search filters, given (a) search term(s) as input.
    ############################################################################

    # These methods all return objects that represent search filters, given a
    # search term or search terms as input. They should return an object with
    # the following properties.
    # - `filter`: the filter itself, i.e., an OLD-style filter, a JSON array.
    # - `description`: a string of HTML describing what the filter does.
    # - `rank`: an integer that ranks how important we think this filter is.
    #           Higher means more important. The rank can be used to choose the
    #           order in which we execute the filter/search on the server.

    # Return a filter that expresses this search: "Give me all forms where the
    # provided search term *is a morpheme in* at least one of the
    # morpheme-containing fields."
    getSearchTermIsAMorphemeFilter: (searchTerm) ->
      if (' ' in searchTerm) or (not searchTerm) then return null
      for delim in @delims
        if delim in searchTerm then return null
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      conjunct = ['or']
      subcomplement = []
      for attributeSet in @morphemeContainingAttributes
        subfilter = [@targetResourceNameCapitalized]
        for attribute in attributeSet
          subfilter.push attribute
        subfilter.push 'regex'
        subfilter
          .push "(^| |#{@delims.join '|'})#{searchTerm}($| |#{@delims.join '|'})"
        subcomplement.push subfilter
      conjunct.push subcomplement
      complement.push conjunct
      filter.push complement
      description = "All #{@targetResourceNamePlural} where
        “#{@highL}#{searchTerm}#{@highR}” is a #{@highL}morpheme#{@highR} in
        at least one of the fields that can contain representations of
        morphemes."
      filter: filter
      description: description
      rank: 8

    # Return a filter that expresses this search: "Give me all forms where the
    # provided search term (a string that may contain multiple words)
    # *is a word in* at least one of the common/likely attribute values."
    getSearchTermIsAWordFilter: (searchTerm) ->
      if (' ' in searchTerm) or (not searchTerm) then return null
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      conjunct = ['or']
      subcomplement = []
      for attributeSet in @wordContainingAttributes
        subfilter = [@targetResourceNameCapitalized]
        for attribute in attributeSet
          subfilter.push attribute
        subfilter.push 'regex'
        subfilter.push "(^| )#{searchTerm}($| )"
        subcomplement.push subfilter
      conjunct.push subcomplement
      complement.push conjunct
      filter.push complement
      description = "All #{@targetResourceNamePlural} where
        “#{@highL}#{searchTerm}#{@highR}” is a #{@highL}word#{@highR} in
        at least one of the fields that can contain words."
      filter: filter
      description: description
      rank: 7

    # Return a filter that expresses this search: "Give me all forms where the
    # provided search term (a string that may contain multiple words)
    # *equals* at least one of the common/likely attribute values."
    getSearchTermEqualsAnyLikelyAttributeFilter: (searchTerm) ->
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      conjunct = ['or']
      subcomplement = []
      for attributeSet in @likelyAttributes
        subfilter = [@targetResourceNameCapitalized]
        for attribute in attributeSet
          subfilter.push attribute
        subfilter.push '='
        subfilter.push searchTerm
        subcomplement.push subfilter
      conjunct.push subcomplement
      complement.push conjunct
      filter.push complement
      description = "All #{@targetResourceNamePlural} where
        “#{@highL}#{searchTerm}#{@highR}” #{@highL}exactly matches#{@highR}
        at least one of the commonly searched fields."
      filter: filter
      description: description
      rank: 9

    # Return a filter that expresses this search: "Give me all forms where the
    # provided search term (a string that may contain multiple words)
    # substring-matches at least one of the common/likely attribute values."
    getSearchTermSubstringMatchesAnyLikelyAttributeFilter: (searchTerm) ->
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      conjunct = ['or']
      subcomplement = []
      for attributeSet in @likelyAttributes
        subfilter = [@targetResourceNameCapitalized]
        for attribute in attributeSet
          subfilter.push attribute
        subfilter.push 'like'
        if searchTerm is '' # An empty search term means "get everything"
          subfilter.push '%'
        else
          subfilter.push "%#{searchTerm}%"
        subcomplement.push subfilter
      conjunct.push subcomplement
      complement.push conjunct
      filter.push complement
      description = "All #{@targetResourceNamePlural} where
        “#{@highL}#{searchTerm}#{@highR}” is a #{@highL}substring#{@highR}
        in at least one of the commonly searched fields."
      filter: filter
      description: description
      rank: 5

    # Return a filter that expresses this search: "Give me all forms where all
    # of the provided search terms *are morphemes in* at least one of
    # morpheme-containing fields."
    getAllSearchTermsAreMorphemesFilter: (searchTerms) ->
      goodSearchTerms = []
      for searchTerm in searchTerms
        if ' ' in searchTerm then continue
        for delim in @delims
          if delim in searchTerm then continue
        goodSearchTerms.push searchTerm
      if goodSearchTerms.length is 0 then return null
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      for searchTerm in goodSearchTerms
        conjunct = ['or']
        subcomplement = []
        for attributeSet in @morphemeContainingAttributes
          subfilter = [@targetResourceNameCapitalized]
          for attribute in attributeSet
            subfilter.push attribute
          subfilter.push 'regex'
          subfilter
            .push "(^| |#{@delims.join '|'})#{searchTerm}($| |#{@delims.join '|'})"
          subcomplement.push subfilter
        conjunct.push subcomplement
        complement.push conjunct
      filter.push complement
      if goodSearchTerms.length is 1
        description = "All #{@targetResourceNamePlural} where
          “#{@highL}#{goodSearchTerms[0]}#{@highR}”
          is a #{@highL}morpheme #{@highR} in at least one of the fields that
          can contain morphemes."
      else if goodSearchTerms.length is 2
        description = "All #{@targetResourceNamePlural} where both
          #{@coordinate goodSearchTerms} are #{@highL}morphemes #{@highR} in at
          least one of the fields that can contain morpheme."
      else
        description = "All #{@targetResourceNamePlural} where all of
          #{@coordinate goodSearchTerms} are #{@highL}morphemes #{@highR} in at
          least one of the fields that can contain morphemes."
      filter: filter
      description: description
      rank: 8

    # Return a filter that expresses this search: "Give me all forms where all
    # of the provided search terms *are words in* at least one of the
    # common/likely attribute values."
    getAllSearchTermsAreWordsFilter: (searchTerms) ->
      goodSearchTerms = (t for t in searchTerms when ' ' not in t)
      if goodSearchTerms.length is 0 then return null
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      for searchTerm in goodSearchTerms
        conjunct = ['or']
        subcomplement = []
        for attributeSet in @wordContainingAttributes
          subfilter = [@targetResourceNameCapitalized]
          for attribute in attributeSet
            subfilter.push attribute
          subfilter.push 'regex'
          subfilter.push "(^| )#{searchTerm}($| )"
          subcomplement.push subfilter
        conjunct.push subcomplement
        complement.push conjunct
      filter.push complement
      if goodSearchTerms.length is 1
        description = "All #{@targetResourceNamePlural} where
          “#{@highL}#{goodSearchTerms[0]}#{@highR}”
          is a #{@highL}word in#{@highR} at least one of the commonly
          searched fields."
      else if goodSearchTerms.length is 2
        description = "All #{@targetResourceNamePlural} where both
          #{@coordinate goodSearchTerms} are #{@highL}words#{@highR} in at
          least one of the fields that can contain words."
      else
        description = "All #{@targetResourceNamePlural} where all of
          #{@coordinate goodSearchTerms} are #{@highL}words #{@highR} in at
          least one of the fields that can contain words."
      filter: filter
      description: description
      rank: 7

    # Return a filter that expresses this search: "Give me all forms where all
    # of the provided search terms *exactly* match at least one of the
    # common/likely attribute values."
    getAllSearchTermsEqualAnyLikelyAttributeFilter: (searchTerms) ->
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      for searchTerm in searchTerms
        conjunct = ['or']
        subcomplement = []
        for attributeSet in @likelyAttributes
          subfilter = [@targetResourceNameCapitalized]
          for attribute in attributeSet
            subfilter.push attribute
          subfilter.push '='
          subfilter.push searchTerm
          subcomplement.push subfilter
        conjunct.push subcomplement
        complement.push conjunct
      filter.push complement
      if searchTerms.length is 1
        description = "All #{@targetResourceNamePlural} where
          “#{@highL}#{searchTerms[0]}#{@highR}”
          #{@highL}exactly matches#{@highR} at least one of the commonly
          searched fields."
      else if searchTerms.length is 2
        description = "All #{@targetResourceNamePlural} where both
          #{@coordinate searchTerms} #{@highL}exactly match#{@highR} at
          least one of the commonly searched fields."
      else
        description = "All #{@targetResourceNamePlural} where all of
          #{@coordinate searchTerms} #{@highL}exactly match#{@highR} at
          least one of the commonly searched fields."
      filter: filter
      description: description
      rank: 9

    # Return a filter that expresses this search: "Give me all forms where all
    # of the provided search terms substring-match at least one of the
    # common/likely attribute values." This is a very weak search, but can be
    # considered as the last resort for what the user may want.
    getAllSearchTermsSubstringMatchAnyLikelyAttributeFilter: (searchTerms) ->
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      for searchTerm in searchTerms
        conjunct = ['or']
        subcomplement = []
        for attributeSet in @likelyAttributes
          subfilter = [@targetResourceNameCapitalized]
          for attribute in attributeSet
            subfilter.push attribute
          subfilter.push 'like'
          if searchTerm is '' # An empty search term means "get everything"
            subfilter.push '%'
          else
            subfilter.push "%#{searchTerm}%"
          subcomplement.push subfilter
        conjunct.push subcomplement
        complement.push conjunct
      filter.push complement
      if searchTerms.length is 1
        description = "All #{@targetResourceNamePlural} where
          “#{@highL}#{searchTerms[0]}#{@highR}” is a
          #{@highL}substring#{@highR} in at least one of the commonly searched
          fields."
      else if searchTerms.length is 2
        description = "All #{@targetResourceNamePlural} where both
          #{@coordinate searchTerms} are #{@highL}substrings#{@highR} in at
          least one of the commonly searched fields."
      else
        description = "All #{@targetResourceNamePlural} where all of
          #{@coordinate searchTerms} are #{@highL}substrings#{@highR} in at
          least one of the commonly searched fields."
      filter: filter
      description: description
      rank: 5

    # Here we assume that the user only wants forms that are grammatical and
    # are real data, i.e., have the status value "tested".
    getGeneralSearchFilterComplement: ->
      [
        ['Form', 'grammaticality', '=', '']
        ['Form', 'status', '=', 'tested']
      ]

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # think the user is likely to want to search over. Extend this array in
    # sub-classes to cover salient attributes, relative to the resource being
    # searched over.
    likelyAttributes: [
      ['id']
      ['transcription']
      ['morpheme_break']
      ['morpheme_gloss']
      ['translations', 'transcription']
    ]

    # Attributes that we expect can contain morphemes, or that we expect users
    # to want to search for morphemes in.
    morphemeContainingAttributes: [
      ['morpheme_break']
      ['morpheme_gloss']
    ]

    # Attributes that we expect can contain words, or that we expect users to
    # want to search for words in.
    wordContainingAttributes: [
      ['transcription']
      ['morpheme_break']
      ['morpheme_gloss']
      ['translations', 'transcription']
    ]

