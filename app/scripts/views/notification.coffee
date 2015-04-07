define [
  './base'
  './../templates/notification'
], (BaseView, notificationTemplate) ->

  # Notification
  # ------------
  #
  # View for a single notification, i.e., a message that pops up in the
  # application.

  class NotificationView extends BaseView

    tagName: 'div'
    className: 'notification ui-corner-all ui-state-default'

    template: notificationTemplate

    events:
      'click': 'destroy'

    destroy: ->
      @$el.slideUp()
      @trigger 'destroySelf', @

    initialize: (options) ->
      @title = options.title or 'title'
      @content = options.content or 'content'
      @type = options.type or 'regular' # options: 'regular', 'error', and 'warning'
      @timer = options.timer or 10000

    render: ->
      @$el
        .hide()
        .html(@template(
          title: @title
          content: @content
          type: @type))
        .slideDown
          complete: =>
            @trigger 'notifierRendered'
      @typify()
      @countdown()
      @

    countdown: ->
      if @timer?
        setTimeout (=> @destroy()), @timer

    typify: ->
      if @type is 'error'
        @$el.addClass 'ui-state-error'
        @$('.icon').addClass 'fa fa-fw fa-exclamation-triangle'
      else if @type is 'warning'
        @$el.addClass 'ui-state-highlight'
        @$('.icon').addClass 'fa fa-fw fa-exclamation-circle'

