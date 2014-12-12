define [
    'backbone',
    './../models/application-settings'
  ], (Backbone, ApplicationSettingsModel) ->

  # Application Settings Collection
  # -------------------------------

  class ApplicationSettingsCollection extends Backbone.Collection

    model: ApplicationSettingsModel
    localStorage: new Backbone.LocalStorage('dativeApplicationSettings')

