define [
  './resources'
  './../models/old-application-settings'
], (ResourcesCollection, OLDApplicationSettingsModel) ->

  # OLD Application Settings Collection
  # -----------------------------------
  #
  # Holds models for OLD application settings.
  #
  # *NOTE:* The OLD has no pagination for its application settings `index`
  # action. This means that all we can do is retrieve *all* of the application
  # settings. As a result, this class overrides the super-class's
  # `fetchResourcesOnloadHandler`.

  class OLDApplicationSettingsCollection extends ResourcesCollection

    resourceName: 'oldApplicationSettings'
    serverSideResourceName: 'applicationsettings'
    model: OLDApplicationSettingsModel

    # Method to handle the `onload` event of a CORS request to fetch all of an
    # OLD web service's application settings resources.
    # Note the strange spellings of the events triggered here; just go along
    # with it ...
    fetchResourcesOnloadHandler: (responseJSON) ->
      Backbone.trigger 'fetchOldApplicationSettingsesEnd'
      if @utils.type(responseJSON) is 'array'
        if responseJSON.length isnt 0
          @reset @getDativeResourceModelsFromOLDObjects(responseJSON)
        Backbone.trigger 'fetchOldApplicationSettingsesSuccess'
      else
        # Failure to retrieve application settings indicates that we are not
        # logged in. `AppView` hears the following event and sets its
        # `@loggedIn` to `false` in response.
        Backbone.trigger 'fetchOldApplicationSettingsesFail',
          'failed to fetch all OLD application settings resources'

