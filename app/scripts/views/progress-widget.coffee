define [
  'backbone'
  './base'
  './../templates/progress-widget'
  'jqueryspin'
], (Backbone, BaseView, progressWidgetTemplate) ->

  # Progress Widget View
  # --------------------
  #
  # Displays spinning ball and flashes messages when events occur.
  #
  # TODO: deprecate this, and just call `spin()` on the relevant view.

  class ProgressWidgetView extends BaseView

    template: progressWidgetTemplate
    spinnerId: '#progress-widget-spinner'

    initialize: ->
      @tasks = {}
      @listenTo Backbone, 'longTask:register', @registerTask
      @listenTo Backbone, 'longTask:deregister', @deregisterTask

    registerTask: (taskName, taskId) ->
      @tasks[taskId] = taskName
      @$el.show()
      @spin()
      @refreshTaskDescriptions()

    deregisterTask: (taskId) ->
      delete @tasks[taskId]
      if Object.keys(@tasks).length is 0
        @stop()
        @$el.hide()

    refreshTaskDescriptions: ->
      tasksList = @$('.progress-widget-tasks ul')
      tasksList.empty()
      for taskId, taskName of @tasks
        tasksList.append "<li>#{taskName}</li>"

    render: ->
      @$el.html(@template()).hide()

    # Make the shadow border of the progress widget pulsate
    pulsate: ->
      @$('.progress-widget').addClass('pulse1')
      f = =>
        @$('.progress-widget').toggleClass 'pulse2'
      setInterval f, 500

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '20px', left: '20px'}

    spin: ->
      @$(@spinnerId).spin @spinnerOptions()

    stop: ->
      @$(@spinnerId).spin false

