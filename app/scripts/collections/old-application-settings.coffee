define [
  './resources'
  './../models/old-application-settings'
], (ResourcesCollection, OLDApplicationSettingsModel) ->

  # OLD Application Settings Collection
  # -----------------------------------
  #
  # Holds models for old application settings.

  class OLDApplicationSettingsCollection extends ResourcesCollection

    resourceName: 'oldApplicationSettings'
    model: OLDApplicationSettingsModel




