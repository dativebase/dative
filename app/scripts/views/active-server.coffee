define [
  'backbone'
  './base'
  './../templates/active-server'
], (Backbone, BaseView, activeServerTemplate) ->

  # Active Server View
  # ------------------
  #
  # A view dedicated to a single jQueryUI selectmenu which indicates the active
  # server. The model is the entire `applicationSettings` instance initialized
  # in `app.coffee`.

  class ActiveServerView extends BaseView

    template: activeServerTemplate

    initialize: ->
      @listenTo @model.get('servers'), 'change', @serverChanged
      @listenTo @model.get('servers'), 'add', @newServerAdded

    render: ->
      context =
        activeServerId: @model.get('activeServer').get('id')
        servers: @model.get('servers').toJSON()
      @$el.html @template(context)
      @$('select.activeServer').selectmenu()

    serverChanged: (serverModel) ->
      @$('select.activeServer')
        .find("option[value=#{serverModel.get('id')}]")
          .text(serverModel.get('name')).end()
        .selectmenu('refresh')

    newServerAdded: (newServerModel) ->
      console.log 'new server added'
      console.log newServerModel
      newOptionElement = $('<option/>',
        value: newServerModel.get('id')
        text: newServerModel.get('name'))
      @$('select.activeServer').prepend(newOptionElement)
        .selectmenu('refresh')

    setFromGUI: ->
      @model.set 'activeServer', @$('select[name=activeServer]').val()

