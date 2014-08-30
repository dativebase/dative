define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
], ( $, _, Backbone, JST, BaseView) ->

  # Application Settings Display View
  # ---------------------------------

  class ApplicationSettingsDisplayView extends BaseView

    template: JST['app/scripts/templates/application-settings-view.ejs']

    render: ->
      @$el.html @template(@model.attributes)
      @_guify()

    _guify: ->
      @$('div.input-display')
        .css("border-color", ApplicationSettingsDisplayView.jQueryUIColors.defBo)
        .mouseover(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .focus(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .mouseout(-> $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
        .blur(-> $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
      @$('button.edit').button().keypress((event) =>
        if event.which in [13, 32]
          event.preventDefault()
          Backbone.trigger 'applicationSettings:edit'
      )

