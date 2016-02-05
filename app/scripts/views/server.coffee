define [
  'backbone'
  './base'
  './../utils/globals'
  './../templates/server'
], (Backbone, BaseView, globals, serverTemplate) ->

  # Server View
  # ------------

  class ServerView extends BaseView

    template: serverTemplate

    initialize: ->
      @applicationSettingsModel = globals.applicationSettings
      @serverTypes = @applicationSettingsModel.get 'serverTypes'
      @serverCodes = @applicationSettingsModel.get 'fieldDBServerCodes'
      @savePending = false

    events:
      'keydown button.delete-server': 'deleteServerKeys'
      'click button.delete-server': 'deleteServerConfirm'
      'keydown button.activate-server': 'activateServerKeys'
      'click button.activate-server': 'activateServer'
      'selectmenuchange': 'toggleServerCodeSelect'

      'input input': 'setModelFromGUI'
      'selectmenuchange': 'setModelFromGUI'

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @listenTo @applicationSettingsModel, 'change:activeServer',
        @activeServerChanged
      @listenTo @applicationSettingsModel, 'change:loggedIn',
        @loggedInChanged
      @listenTo @model, 'change:name', @changeHeaderName
      @listenTo Backbone, 'deleteServer', @deleteServer
      @delegateEvents()

    loggedIn: ->
      @applicationSettingsModel.get 'loggedIn'

    changeHeaderName: ->
      @$('.dative-widget-header-title span.header-title-name')
        .text @model.get('name')

    toggleServerCodeSelect: ->
      if @$('select[name=type]').first().val() is 'FieldDB'
        @$('li.serverCode').slideDown()
      else
        @$('li.serverCode').slideUp()

    activeServerChanged: ->
      @guify()

    loggedInChanged: ->
      @guify()

    isActive: ->
      @model is @applicationSettingsModel.get 'activeServer'

    setModelFromGUI: ->
      @$('input, select').each (index, element) =>
        @model.set $(element).attr('name'), $(element).val()
      # If a change occurs on a server, we auto-save to localStorage after a
      # 3-second delay.
      if not @savePending
        @savePending = true
        setTimeout (=> @triggerSave()), 3000

    # Trigger a 'saveServers' event which will cause the
    # `ApplicationSettingsView` to save all server settings to localStorage
    # and, crucially, document the fact that we have modified the servers.
    triggerSave: ->
      @savePending = false
      Backbone.trigger 'saveServers'

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    html: ->
      headerTitle = if @isActive() then 'Active Server' else 'Server'
      context = _.extend(@model.attributes
        {
          serverTypes: @serverTypes,
          serverCodes: @serverCodes,
          isActive: @isActive(),
          headerTitle: headerTitle
        }
      )
      @$el.html @template(context)

    # Trigger opening of a confirm dialog: if user clicks "Ok", then this
    # server will be deleted.
    deleteServerConfirm: (event) ->
      if event then @stopEvent event
      options =
        text: "Do you really want to delete the server called “#{@model.get('name')}”?"
        confirm: true
        confirmEvent: 'deleteServer'
        confirmArgument: @model.get('id')
      Backbone.trigger 'openAlertDialog', options

    # Really delete this server
    deleteServer: (serverId) ->
      if serverId is @model.get('id')
        @$el.slideUp 'medium', =>
          @model.trigger 'removeme', @model
          Backbone.trigger 'removeServerView', @
          @remove()

    deleteServerKeys: (event) ->
      if event.which is 13
        @stopEvent event
        @deleteServerConfirm()

    activateServerKeys: ->
      if event.which is 13
        event.preventDefault()
        event.stopPropagation()
        @activateServer()

    setActivateServerButtonStateActive: ->
      @$('button.activate-server')
        .find('i').addClass('fa-toggle-on').removeClass('fa-toggle-off').end()
        .button()
        .tooltip content: 'this is the active server'

    setActivateServerButtonStateInactive: ->
      @$('button.activate-server')
        .find('i').addClass('fa-toggle-off').removeClass('fa-toggle-on').end()
        .button()
        .tooltip content: 'make this server the active one'

    activateServer: ->
      # The ApplicationSettingsView changes the active server.
      Backbone.trigger 'activateServer', @model.get('id')

    activateShouldBeDisabled: ->
      if @loggedIn() or @controlsShouldBeDisabled() then true else false

    controlsShouldBeDisabled: -> if @isActive() then true else false

    guify: ->
      @buttonSetup()
      @displayActivity()
      @inputSetup()
      @selectmenuSetup()
      @tabindicesNaught() # active elements have tabindex=0

    # Visual indication reflecting whether the server is active.
    displayActivity: ->
      if @isActive()
        @$('.dative-widget-header-title span.active-indicator')
          .text '(active)'
          .css("color", @constructor.jQueryUIColors().defCo)
        @$('.dative-widget-body').addClass 'ui-state-highlight ui-corner-bottom'
        @setActivateServerButtonStateActive()
      else
        @$('.dative-widget-header-title span.active-indicator').text ''
        @$('.dative-widget-body').removeClass 'ui-state-highlight ui-corner-bottom'
        @setActivateServerButtonStateInactive()

    buttonSetup: ->

      #@$('button').button().attr('tabindex', 0)

      $deleteButton = @$('button.delete-server')
      deleteButtonAlreadyButton = $deleteButton.button 'instance'
      $deleteButton
        .button
          disabled: @controlsShouldBeDisabled()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"
      if deleteButtonAlreadyButton then $deleteButton.button 'refresh'

      $activateButton = @$('button.activate-server')
      activateButtonAlreadyButton = $activateButton.button 'instance'
      $activateButton
        .button
          disabled: @activateShouldBeDisabled()
        .tooltip
          position:
            my: "right-70 center"
            at: "left center"
            collision: "flipfit"
      if activateButtonAlreadyButton then $activateButton.button 'refresh'

    inputSetup: ->
      @$('input')
        .prop 'disabled', @controlsShouldBeDisabled()
        .tooltip
          position:
            my: "right-90 center"
            at: "left center"
            collision: "flipfit"

    selectmenuSetup: ->

      controlsShouldBeDisabled = @controlsShouldBeDisabled()
      width = 320

      $typeSelect = @$('select[name=type]')
      typeSelectAlreadySelectmenu = $typeSelect.selectmenu 'instance'
      $typeSelect
        .selectmenu
          width: width
          disabled: controlsShouldBeDisabled
        .next('.ui-selectmenu-button').addClass 'server-type'
      if typeSelectAlreadySelectmenu then $typeSelect.selectmenu 'refresh'

      $serverCodeSelect = @$('select[name=serverCode]')
      serverCodeSelectAlreadySelectmenu = $serverCodeSelect.selectmenu 'instance'
      $serverCodeSelect
        .selectmenu
          width: width
          disabled: controlsShouldBeDisabled
        .next('.ui-selectmenu-button').addClass 'server-code'
      if serverCodeSelectAlreadySelectmenu
        $serverCodeSelect.selectmenu 'refresh'

      position =
        my: "right-90 center"
        at: "left center"
        collision: "flipfit"

      @$('.ui-selectmenu-button').filter('.server-type')
        .tooltip
          items: 'span'
          content: "Is it a FieldDB server or an OLD one?"
          position: position

      @$('.ui-selectmenu-button').filter('.server-code').each ->
        $(@).tooltip
          items: 'span'
          content: "Choose a server code (for FieldDB servers only)"
          position: position

      if @model.get('type') is 'OLD' then @$('li.serverCode').hide()

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors().defBo)
        .attr('tabindex', 0)

