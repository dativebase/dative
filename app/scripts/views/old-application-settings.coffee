define [
  './resources'
  './old-application-settings-resource'
  './../collections/tags'
  './../models/tag'
  './../utils/globals'
], (ResourcesView, OLDApplicationSettingsResourceView,
  OLDApplicationSettingsCollection, OLDApplicationSettingsModel, globals) ->

  # OLD Application Settings View
  # -----------------------------
  #
  # Displays a collection of OLD application settings for browsing, with
  # pagination. Also contains a model-less `OLDApplicationSettingsResourceView`
  # instance for creating new OLD application settings within the browse
  # interface.

  class OLDApplicationSettingsView extends ResourcesView

    resourceName: 'oldApplicationSettings'
    resourceView: OLDApplicationSettingsResourceView
    resourcesCollection: OLDApplicationSettingsCollection
    resourceModel: OLDApplicationSettingsModel

