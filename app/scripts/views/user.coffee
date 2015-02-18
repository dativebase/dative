define [
  'backbone'
  './base'
  './../templates/user'
], (Backbone, BaseView, userTemplate) ->

  # User View
  # ---------
  #
  # Small view for showing which users have access to a given corpus.

  class UserView extends BaseView

    initialize: (options) ->
      @loggedInUserRole = options.loggedInUserRole

    tagName: 'div'
    className: 'dative-user-widget ui-widget ui-widget-content ui-corner-all'
    template: userTemplate

    events:
      'keydown button.revoke-access': 'revokeAccessKeys'
      'click button.revoke-access': 'revokeAccess'

    listenToEvents: ->
      @listenTo @model, 'change', @modelChanged
      @delegateEvents()

    modelChanged: ->
      @render()

    render: ->
      @$el.html @template(@model.attributes)
      @guify()
      @listenToEvents()
      @

    guify: ->

      disabled = not @userAccessCanBeRevoked()

      @$('button.revoke-access')
        .button
          disabled: disabled
        .tooltip
          position:
            my: 'left+10 center'
            at: 'right center'
            collision: 'flipfit'

      if disabled
        @$('button.revoke-access').hide()
        @$('div.dative-widget-header').height 'auto'

      if @userIsLoggedInUser() then @$el.addClass 'ui-state-highlight'

    userAccessCanBeRevoked: ->
      if @loggedInUserRole is 'admin'
        if @userIsLoggedInUser() then false else true
      else
        false

    userIsLoggedInUser: ->
      if @model.get('loggedInUsername') is @model.get('username')
        true
      else
        false

    revokeAccessKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @revokeAccess event

    revokeAccess: (event) ->
      @stopEvent event
      username = @model.get 'username'
      @disableRevokeButton()
      @trigger 'request:revokeAccess', username

    disableRevokeButton: ->
      @$('button.revoke-access').button disabled: true

