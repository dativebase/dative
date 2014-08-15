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
      #@_setFocus()

    _guify: ->
      @$('div.input-display')
        .css("border-color", ApplicationSettingsDisplayView.jQueryUIColors.defBo)
        .mouseover(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .focus(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .mouseout(-> $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
        .blur(-> $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
      @$('button.edit').button().keypress((e) =>
        if e.which is 13
          e.preventDefault()
          Backbone.trigger 'applicationSettings:edit'
      )

    _setFocus: ->
      console.log 'IN VIEW SET FOCUS'
      if @focusedElementId
        console.log 'WE HAVE FOCUSED ELEMENT ID!'
        @$("##{@focusedElementId}").first().focus().select()
      else
        console.log 'WE WILL FOCUS FIRST BUTTON'
        console.log $('button.edit').first()
        $('button.edit').first().focus()



