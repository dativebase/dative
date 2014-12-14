define [
  'backbone'
  './base'
  './../templates/application-settings-view'
], (Backbone, BaseView, applicationSettingsViewTemplate) ->

  # Application Settings Display View
  # ---------------------------------

  class ApplicationSettingsDisplayView extends BaseView

    template: applicationSettingsViewTemplate
    render: ->
      @$el.html @template(@model.attributes)

