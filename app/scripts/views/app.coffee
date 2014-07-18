# # App View
#
#   AppView is the Dative application core.

define [
  'jquery',
  'lodash',
  'backbone',
  'views/mainmenu',
  'views/pages',
  'views/form-add'
], ($, _, Backbone, MainMenuView, PagesView, FormAddView) ->

  class AppView extends Backbone.View
    template: JST['app/scripts/templates/app.ejs']
    el: '#oldclientapp'
    subviews:
      pagesView: PagesView
      formAddView: FormAddView
    activeSubview: null

    initialize: ->
      # Get the jQuery UI colors
      @jQueryUIColors = $.getJQueryUIColors()

      # Main menu triggers custom events -- handle them here
      @mainMenuView = new MainMenuView()
      @mainMenuView.parent = @

      @mainMenuView.on 'request:pages', @activatePagesView, @
      @mainMenuView.on 'request:formAdd', @activateFormAddView, @

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
      appView = @
      @$('#appview').css height: $(window).height() - 50
      $(window).resize ->
        appView.$('#appview').css height: $(window).height() - 50

