define [
  'backbone'
  './../templates'
  './base'
], (Backbone, JST, BaseView) ->

  # Application Settings Edit View
  # ---------------------------------

  class ApplicationSettingsEditView extends BaseView

    template: JST['app/scripts/templates/application-settings-edit.ejs']

    render: ->
      @$el.html @template(@model.attributes)

