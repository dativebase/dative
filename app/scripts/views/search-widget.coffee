define [
  './base'
  './resource'
  './search-add-widget'
  './search-field'
  './../models/search'
  './../models/form'
  './../templates/search-widget'
], (BaseView, ResourceView, SearchAddWidgetView, SearchFieldView, SearchModel,
  FormModel, searchWidgetTemplate) ->

  # Search Widget
  # -------------
  #
  # A view that contains just a SearchFieldView and a button for performing the
  # search.

  class SearchFieldViewNoLabel extends SearchFieldView

    showLabel: false


  class SearchWidget extends ResourceView

    resourceName: 'search'
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
      'keydown': 'stopPropagation'

    stopPropagation: (event) ->
      event.stopPropagation()

    search: ->
      Backbone.trigger(
        'request:formsBrowseSearchResults',
        search: @model.get('search'))

    count: ->
      console.log 'you want to count the results of this search'

    save: ->
      console.log 'you want to save this search'

    hideMe: ->
      @trigger 'hideMe'

    # Tell the Help dialog to open itself and search for "searching forms" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: 'searching forms'
        scrollToIndex: 1
      )

    initialize: ->
      @mixinSearchAddWidgetView()
      @model = new SearchModel()
      @formModel = new FormModel()
      @listenToEvents()

    # Appropriate a subset of the methods of `SearchAddWidgetView`.
    mixinSearchAddWidgetView: ->
      methodsWeWant = [
        'storeOptionsDataGlobally'
        'weHaveNewResourceData'
        'getNewResourceDataStart'
        'getNewResourceDataEnd'
        'getNewResourceDataSuccess'
        'getNewResourceDataFail'
        'getOptions'
      ]
      for method in methodsWeWant
        @[method] = SearchAddWidgetView::[method]

    render: ->
      if not @weHaveNewResourceData()
        @model.getNewResourceData() # Success in this request will call `@render()`
        return
      @searchFieldView = @getSearchFieldView()
      @html()
      @guify()
      @renderSearchFieldView()
      @listenToEvents()
      @

    getSearchFieldView: ->
      new SearchFieldViewNoLabel
        resource: 'forms'
        attribute: 'search'
        model: @model
        options: @getOptions()

    listenToEvents: ->
      # Events specific to an OLD backend and the request for the data needed
      # to create a resource.
      @listenTo Backbone, "getNewSearchDataStart",
        @getNewResourceDataStart
      @listenTo Backbone, "getNewSearchDataEnd",
        @getNewResourceDataEnd
      @listenTo Backbone, "getNewSearchDataSuccess",
        @getNewResourceDataSuccess
      @listenTo Backbone, "getNewSearchDataFail",
        @getNewResourceDataFail

    renderSearchFieldView: ->
      @$('ul.primary-data').append @searchFieldView.render().el
      @rendered @searchFieldView

    html: ->
      @$el.html @template()

    guify: ->
      @buttonify()
      @tooltipify()
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

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
      @$('.dative-widget-header .hide-search-resource-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('ul.button-only-fieldset button.dative-tooltip').tooltip()

