define [
  './base'
  './search-field'
  './../models/search'
  './../templates/search-widget'
], (BaseView, SearchFieldView, SearchModel, searchWidgetTemplate) ->

  # Search Widget
  # -------------
  #
  # A view that contains just a SearchFieldView and a button for performing the
  # search.
  #
  # TODO: this is a very ad hoc view and one which overlaps too much with
  # SearchAddWidgetView. I should probably just modify the search add widget
  # and use it here instead of this view.

  class SearchWidget extends BaseView

    tagName: 'div'
    className: 'dative-search-widget dative-shadowed-widget
      dative-widget-center ui-widget ui-widget-content ui-corner-all'
    template: searchWidgetTemplate

    initialize: ->
      @model = new SearchModel()
      @searchFieldView = new SearchFieldView
        resource: 'forms'
        attribute: 'search'
        model: @model
        options: {}
      @listenToEvents()

    render: ->
      if not @weHaveNewResourceData()
        @model.getNewResourceData() # Success in this request will call `@render()`
        return
      @html()
      @guify()
      @renderSearchFieldView()
      @listenToEvents()
      @

    listenToEvents: ->
      super
      # Events specific to an OLD backend and the request for the data needed to create a resource.
      @listenTo Backbone, "getNewSearchDataStart",
        @getNewSearchDataStart
      @listenTo Backbone, "getNewSearchDataEnd",
        @getNewSearchDataEnd
      @listenTo Backbone, "getNewSearchDataSuccess",
        @getNewSearchDataSuccess
      @listenTo Backbone, "getNewSearchDataFail",
        @getNewSearchDataFail

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

