# # App View
#
#   AppView is the Dative application core.

define [
  'jquery',
  'lodash',
  'backbone',
  'views/base',
  'views/mainmenu',
  'views/pages',
  'views/form-add'
], ($, _, Backbone, BaseView, MainMenuView, PagesView, FormAddView) ->

  class AppView extends BaseView

    template: JST['app/scripts/templates/app.ejs']
    el: '#oldclientapp'
    subviews:
      pagesView: PagesView
      formAddView: FormAddView
    activeSubview: null

    initialize: ->

      # Main menu triggers custom events -- handle them here
      @mainMenuView = new MainMenuView()

      @mainMenuView.on '_request:pages', @activatePagesView, @
      @mainMenuView.on 'f_ormAdd', @activateFormAddView, @

      @render()

    render: ->
      @$el.html @template()
      @mainMenuView.setElement('#mainmenu').render()
      @matchWindowDimensions()

    # Call render on the active subview, setting its el to '#appview'
    renderSubview: ->
      @activeSubview.render()

    activateFormAddView: ->
      @activeSubview = @subviews['formAddView']
      if not @activeSubview.initialized
        @activeSubview = new @activeSubview()
        @activeSubview.parent = @
        @subviews['formAddView'] = @activeSubview
      @activeSubview.setElement '#appview'
      @renderSubview()

    # Make the pagesView the active subview of the app and render it
    activatePagesView: ->
      @activeSubview = @subviews['pagesView']
      if not @activeSubview.initialized
        @activeSubview = new @activeSubview()
        @activeSubview.parent = @
        @subviews['pagesView'] = @activeSubview
      @activeSubview.setElement '#appview'
      @renderSubview()

    # Size the #appview div relative to the window size
    matchWindowDimensions: ->
      @$('#appview').css height: $(window).height() - 50
      $(window).resize =>
        @$('#appview').css height: $(window).height() - 50

