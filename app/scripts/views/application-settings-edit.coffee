define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
], ( $, _, Backbone, JST, BaseView) ->

  # Application Settings Edit View
  # ---------------------------------

  class ApplicationSettingsEditView extends BaseView

    template: JST['app/scripts/templates/application-settings-edit.ejs']

    render: ->
      @$el.html @template(@model.attributes)
      @_guify()
      #@_setFocus()

    _guify: ->
      @$('select, input, textarea, div.input-display')
        .css("border-color", ApplicationSettingsEditView.jQueryUIColors.defBo)
      @$('button.save').button().keypress((event) ->
        if event.which is 13
          event.preventDefault()
          event.stopPropagation()
          Backbone.trigger 'applicationSettings:save'
      )
      @$('button.view').button().keypress((event) ->
        if event.which is 13
          event.preventDefault()
          event.stopPropagation()
          Backbone.trigger 'applicationSettings:view'
      )
      #$('input').keypress((event) ->
      #if event.which is 13
      #event.preventDefault()
      #event.stopPropagation()
      ##Backbone.trigger 'applicationSettings:save'
      #)

    _setFocus: ->
      console.log 'IN EDIT SET FOCUS'
      if @focusedElementId
        @$("##{@focusedElementId}").first().focus().select()
      else
        $('input').first().focus()

