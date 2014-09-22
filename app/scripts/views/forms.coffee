define [
  'backbone'
  './base'
  './form'
  './../templates/forms'
], (Backbone, BaseView, FormView, formsTemplate) ->

  # Forms View
  # -----------
  #
  # Displays a list of forms.

  class FormsView extends BaseView

    template: formsTemplate

    initialize: (options) ->
      @applicationSettings = options.applicationSettings or {}
      #@listenTo @collection, 'change', @_renderCollection
      #@listenTo @collection, 'add', @_renderCollection
      @_renderedFormViews = []

    render: ->
      console.log 'IN RENDER OF FORMS VIEW'
      params =
        paginator:
          itemCount: 2
          pageCount: 1
      @$el.html @template(params)
      @matchHeights()
      @collection.fetch
        itemsPerPage: @applicationSettings.get 'itemsPerPage'
      @_renderCollection()

      # TODO: bind the collection's 'change' event to the construction and
      # rendering of all of the models (in the page of paginator)

      # Asynchronous GET request
      #$.get('form/browse_ajax', options, OLD.forms.handlePaginatorResponse, 'json');

    # See this `curl` command for what the OLD API returns:
    # curl --cookie-jar my-cookies.txt --header "Content-Type: application/json" --data '{"username": "admin", "password": "adminA_1"}' http://127.0.0.1:5000/login/authenticate
    _renderCollection: ->
      console.log '_renderCollection called'
      @$('.dative-pagin-items').html ''
      @_closeRenderedForms()
      @collection.each (model, index) => @_appendView(model, index)

    _closeRenderedForms: ->
      while @_renderedFormViews.length
        formView = @_renderedFormViews.pop()
        formView.close()
        @closed formView

    _appendView: (model, index) ->
      formView = new FormView model: model
      formView.render()
      @_renderedFormViews.push formView
      @rendered formView
      @$('.dative-pagin-items').append @_paginItemTable(formView.$el, index)

    # Return the form view wrapped in a pagination item <table>
    _paginItemTable: (formView$el, index) ->
      $('<table>')
        .addClass('dative-pagin-item')
        .append($('<tbody>')
          .append($('<tr>')
            .append($('<td>')
              .addClass('dative-pagin-item-index')
              .text("(#{index + 1})"))
            .append($('<td>')
              .addClass('dative-pagin-item-content')
              .html(formView$el))))

