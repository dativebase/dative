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

    tagName: 'div'
    className: 'dative-user-widget ui-widget ui-widget-content ui-corner-all'
    template: userTemplate

    events:
      'keydown button.remove': 'removeKeys'
      'click button.remove': 'remove'

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

      @$('button.revoke-privileges')
        .button
          icons: {primary: 'ui-icon-close'},
          text: false

      @$('button.change-role')
        .button
          icons: {primary: 'ui-icon-triangle-2-n-s'},
          text: false

