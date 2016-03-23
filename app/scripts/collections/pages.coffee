define [
    './resources'
    './../models/page'
    './../utils/globals'
  ], (ResourcesCollection, PageModel, globals) ->

  # Pages Collection
  # ----------------
  #
  # Holds models for pages.

  class PagesCollection extends ResourcesCollection

    resourceName: 'page'
    model: PageModel

    # If the home page is updated, we need to tell the `AppView` about that.
    updateResourceOnloadHandler: (resource, responseJSON, xhr, payload) ->
      @checkForHomePageChange responseJSON, xhr
      super resource, responseJSON, xhr, payload

    # If a 'home' page has just been created, we need to tell the `AppView`
    # about that.
    addResourceOnloadHandler: (resource, responseJSON, xhr, payload) ->
      @checkForHomePageChange responseJSON, xhr
      super resource, responseJSON, xhr, payload

    checkForHomePageChange: (responseJSON, xhr) ->
      if xhr.status is 200 and responseJSON.name == 'home'
        globals.applicationSettings.set 'homepage', responseJSON
        globals.applicationSettings.save()
        Backbone.trigger 'homePageChanged'

