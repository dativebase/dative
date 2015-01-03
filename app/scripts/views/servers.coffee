define [
  'backbone'
  './base'
  './server'
  './../models/server'
  './../templates/servers'
  'perfectscrollbar'
], (Backbone, BaseView, ServerView, ServerModel, serversTemplate) ->

  # Servers View
  # -------------
  #
  # A view for a collection of server objects.

  class ServersView extends BaseView

    tagName: 'div'
    template: serversTemplate

    initialize: (options) ->
      @serverTypes = options.serverTypes
      @serverViews = []
      @collection.each (server) =>
        newServerView = new ServerView
          model: server
          serverTypes: @serverTypes
        @serverViews.push newServerView
      @bodyVisible = false

    listenToEvents: ->
      @listenTo Backbone, 'removeServerView', @removeServerView
      @delegateEvents()

    removeServerView: (serverView) ->
      @serverViews = _.without @serverViews, serverView
      serverView.close()
      @closed serverView
      @emptyMessage()

    emptyMessage: ->
      if @serverViews.length is 0
        @$('div.no-servers-msg').show()
      else
        @$('div.no-servers-msg').hide()

    events:
      'keydown button.toggle-appear': 'toggleServerConfigKeys'
      'keydown button.add-server': 'addServerKeys'
      'click button.toggle-appear': 'toggleServerConfig'
      'click button.add-server': 'addServer'

    render: ->
      @$el.html @template()
      @guify()
      @$widgetBody = @$('div.dative-widget-body').first()
      container = document.createDocumentFragment()
      for serverView in @serverViews
        container.appendChild serverView.render().el
        @rendered serverView
      @$widgetBody.append container
      @emptyMessage()
      @listenToEvents()
      @

    setCollectionFromGUI: ->
      updatedServerModels = []
      for serverView in @serverViews
        serverView.setModelFromGUI()
        updatedServerModels.push serverView.model
      @collection.add updatedServerModels

    addServer: (event) ->
      if event
        event.preventDefault()
        event.stopPropagation()
      @openServerConfig()
      serverModel = new ServerModel()
      @collection.unshift serverModel
      serverView = new ServerView
        model: serverModel
        serverTypes: @serverTypes
      @serverViews.unshift serverView
      serverView.render().$el.prependTo(@$widgetBody).hide().slideDown('slow')
      @rendered serverView
      @emptyMessage()

    guify: ->

      @$('button').button().attr('tabindex', 0)

      triangleIcon = 'ui-icon-triangle-1-s'
      if not @bodyVisible
        @$('.dative-widget-body').first().hide()
        triangleIcon = 'ui-icon-triangle-1-e'

      @$('button.toggle-appear')
        .button
          icons: {primary: triangleIcon}
          text: false
        .tooltip()

      @$('button.add-server')
        .button
          icons: {primary: 'ui-icon-plusthick'}
          text: false
        .tooltip()

    toggleServerConfig: (event) ->
      if event
        event.preventDefault()
        event.stopPropagation()

      @$('.toggle-appear .ui-button-icon-primary')
        .toggleClass 'ui-icon-triangle-1-e ui-icon-triangle-1-s'

      @$('.dative-widget-body').first()
        .slideToggle
          complete: =>
            @$('.dative-widget-header').first().toggleClass 'header-no-body'
            $firstInput = @$('input[name=name]').first()
            if $firstInput.is(':visible')
              @$('button.toggle-appear').tooltip content: 'hide servers'
              $firstInput.focus()
            else
              @$('button.toggle-appear').tooltip content: 'show servers'
            @bodyVisible = @$('.dative-widget-body').is(':visible')

    openServerConfig: ->
      if not @$('.dative-widget-body').is(':visible')
        @toggleServerConfig()

    closeServerConfig: ->
      if @$('.dative-widget-body').is(':visible')
        @toggleServerConfig()

    rememberTarget: (event) ->
      try
        @$('.dative-input-display').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    stopEvent: (event) ->
      event.preventDefault()
      event.stopPropagation()

    toggleServerConfigKeys: (event) ->
      @rememberTarget event
      if event.which in [13, 37, 38, 39, 40] then @stopEvent event
      switch event.which
        when 13 # Enter
          @toggleServerConfig()
        when 37, 38 # left and up arrows
          @closeServerConfig()
        when 39, 40 # right and down arrows
          @openServerConfig()

    addServerKeys: (event) ->
      @rememberTarget event
      if event.which is 13 # Enter
        @stopEvent event
        @addServer()

