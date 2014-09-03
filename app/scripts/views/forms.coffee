define [
  'jquery'
  'lodash'
  'backbone'
  './../utils/utils'
  './basepage'
  './form'
], ($, _, Backbone, utils, BasePageView, FormView) ->

  # Forms View
  # -----------
  #
  # Displays a list of forms.

  class FormsView extends BasePageView

    template: JST['app/scripts/templates/forms.ejs']

    initialize: ->
      #@collection.fetch()
      #console.log @collection.length
      @listenTo @collection, 'change', @renderModelViews
      @listenTo @collection, 'add', @renderModelViews

    render: (options) ->
      console.log 'render called on FormsView'

      # Forms list's DOM real estate
      params = headerTitle: 'Forms'
      @$el.html @template(params)
      @matchHeights()
      body = $('#dative-page-body')

      # Tell the paginator how many items_per_page we want
      options = options or {}
      _.extend options, items_per_page: FormsView.userSettings.formItemsPerPage

      # Tell the forms collection to fetch its data
      # The collection currently overrides .fetch() with a CORS request ...
      @collection.fetch()

      # TODO: bind the collection's 'change' event to the construction and 
      # rendering of all of the models (in the page of paginator)

      # Asynchronous GET request
      #$.get('form/browse_ajax', options, OLD.forms.handlePaginatorResponse, 'json');

    renderModelViews: ->

      console.log 'change event on collection triggered'
      #curl --cookie-jar my-cookies.txt --header "Content-Type: application/json" --data '{"username": "admin", "password": "adminA_1"}' http://127.0.0.1:5000/login/authenticate

      @collection.each((model) =>
        @$('#dative-page-body').append(new FormView({model: model}).render().$el))

