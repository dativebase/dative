define [
  'backbone'
  './base'
  './../templates/application-settings-edit'
], (Backbone, BaseView, applicationSettingsEditTemplate) ->

  # Application Settings Edit View
  # ---------------------------------

  class ApplicationSettingsEditView extends BaseView

    template: applicationSettingsEditTemplate

    render: ->
      @$el.html @template(@model.attributes)

