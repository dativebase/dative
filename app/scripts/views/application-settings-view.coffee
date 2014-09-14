define [
  'backbone'
  './../templates'
  './base'
], (Backbone, JST, BaseView) ->

  # Application Settings Display View
  # ---------------------------------

  class ApplicationSettingsDisplayView extends BaseView

    template: JST['app/scripts/templates/application-settings-view.ejs']

    render: ->
      @$el.html @template(@model.attributes)

