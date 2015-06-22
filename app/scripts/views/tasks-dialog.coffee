define [
  'backbone'
  './base'
  './related-model-representation'
  './morphology'
  './../models/morphology'
  './../templates/tasks-dialog'
  './../templates/task'
], (Backbone, BaseView, RelatedModelRepresentationView, MorphologyView,
  MorphologyModel, tasksDialogTemplate, taskTemplate) ->

  # `LinkView` displays a model as a link that when clicked cases the resource
  # displayer dialog to display a view of the model in the displayer dialog.
  class LinkView extends RelatedModelRepresentationView

    getId: -> @context.model.get 'id'

  # `TaskView` is a view for a single task.
  class TaskView extends BaseView

    tagName: 'tr'
    template: taskTemplate

    initialize: (options) ->
      @task = options.task
      @resourceName = @task.resourceName
      @taskName = @utils.camel2regular @task.taskName
      @id = @task.resourceModel.get('id')
      start = @task.taskStartTimestamp
      end = @task.taskEndTimestamp
      @startDate = @utils.humanDatetime(new Date(start))
      if end
        @timeElapsed = @utils.millisecondsToTimeString(end - start)
        @endDate = @utils.humanDatetime(new Date(end))
        @successful = @task.successful
      else
        now = new Date().getTime()
        @timeElapsed = @utils.millisecondsToTimeString(now - start)
        @endDate = 'N/A'
        @successful = 'N/A'
      @resourceRepresentationView =
        new LinkView(
          relatedModelClass: MorphologyModel
          relatedModelViewClass: MorphologyView
          attribute: 'morphology'
          model: @task.resourceModel
          class: 'morphology'
          value:
            name: "#{@task.resourceModel.get('name')}
              #{@task.resourceModel.get('id')}"
        )

    render: ->
      @$el.append @template(
        resourceName: @resourceName
        taskName: @taskName
        successful: @successful
        id: @id
        startDate: @startDate
        endDate: @endDate
        timeElapsed: @timeElapsed
      )
      @resourceRepresentationView
        .setElement @$('.resource-representation').first()
      @resourceRepresentationView.render()
      @rendered @resourceRepresentationView
      @


  # TasksDialogView
  # ---------------
  #
  # This is a dialog box for showing the user the long-running tasks that are
  # pending. Examples of such long-running tasks are compile or
  # generate-and-compile requests against FST-based recources.

  class TasksDialogView extends BaseView

    template: tasksDialogTemplate

    taskViews: []

    closeTaskViews: ->
      while @taskViews.length
        taskView = @taskViews.pop()
        taskView.close()

    initialize: ->
      @listenTo Backbone, 'tasksDialog:toggle', @toggle
      @listenTo Backbone, 'openTasksDialog', @dialogOpen
      @listenTo Backbone, 'longRunningTask', @pollLongRunningTask
      @listenTo Backbone, 'longRunningTaskPreflight',
        @longRunningTaskPreflight
      @listenTo @model, 'change:longRunningTasks', @displayTasks

    events:
      'dialogdragstart': 'closeAllTooltips'

    render: ->
      @$el.append @template(@model.attributes)
      @$target = @$ '.dative-tasks-dialog-target' # outer DIV to which jQueryUI dialog appends
      @dialogify()
      @displayTasks()
      setInterval (=> @displayCurrentTasks()), 1000
      @

    displayTasks: ->
      @closeTaskViews()
      @displayCurrentTasks()
      @displayTerminatedTasks()

    displayCurrentTasks: ->
      longRunningTasks = @model.get 'longRunningTasks'
      $tasksTable = @$('div.dative-tasks-content .current-tasks-table
        table.tasks-table')
      if longRunningTasks.length is 0
        $tasksTable.hide()
        @$('.no-current-tasks').show()
      else
        @$('.no-current-tasks').hide()
        tasksTable = @getTasksTable longRunningTasks
        $tasksTable.show().find('tbody').html tasksTable
        $tasksTable.find('.live-task').spin @spinnerOptions()

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '75%', left: '100%'}

    displayTerminatedTasks: ->
      longRunningTasksTerminated = @model.get 'longRunningTasksTerminated'
      $tasksTable = @$('div.dative-tasks-content .terminated-tasks-table
        table.tasks-table')
      if longRunningTasksTerminated.length is 0
        $tasksTable.hide()
        @$('.no-terminated-tasks').show()
      else
        @$('.no-terminated-tasks').hide()
        tasksTable = @getTasksTable longRunningTasksTerminated, true, false
        $tasksTable.show().find('tbody').html tasksTable

    getTasksTable: (longRunningTasks, reverse=false) ->
      container = document.createDocumentFragment()
      if reverse
        iterator = longRunningTasks[...].reverse()
      else
        iterator = longRunningTasks
      for task in iterator
        taskView = new TaskView(task: task)
        container.appendChild taskView.render().el
        @rendered taskView
        @taskViews.push taskView
      container

    getTasksTable_bk: (longRunningTasks, reverse=false, live=true) =>
      if live
        liveTH = '<th></th>'
        liveTD = '<td class="live-task-container"><div
          class="live-task"></div></td>'
      else
        liveTH = ''
        liveTD = ''
      table = ["<table class='tasks-table'>
        <tr>
          #{liveTH}
          <th>Resource</th>
          <th>Task</th>
          <th>Time Elapsed</th>
          <th>Start Time</th>
          <th>End Time</th>
        </tr>"]
      if reverse
        iterator = longRunningTasks[...].reverse()
      else
        iterator = longRunningTasks
      for task in iterator
        id = task.resourceModel.get('id')
        start = task.taskStartTimestamp
        end = task.taskEndTimestamp
        startDate = @utils.humanDatetime(new Date(start))
        if end
          timeElapsed = @utils.millisecondsToTimeString(end - start)
          endDate = @utils.humanDatetime(new Date(end))
        else
          now = new Date().getTime()
          timeElapsed = @utils.millisecondsToTimeString(now - start)
          endDate = 'N/A'
        table.push "<tr>
          #{liveTD}
          <td>#{task.resourceName} #{id}</td>
          <td>#{@utils.camel2regular task.taskName}</td>
          <td class='time-elapsed'>#{timeElapsed}</td>
          <td>#{startDate}</td>
          <td>#{endDate}</td>
          </tr>"
      table.push "</table>"
      table.join '\n'

    # Transform the tasks dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$('.dative-tasks-dialog').first().dialog
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$target
        dialogClass: 'dative-tasks-dialog-widget dative-shadowed-widget'
        title: 'Tasks'
        width: '60em'
        height: $(window).height() * 0.333
        position:
          my: 'left bottom'
          at: 'left bottom'
          of: window
        create: =>
          @$target.first().find('button').attr('tabindex', 0)
          @fontAwesomateCloseIcon()
        open: =>
          console.log 'in open'
          setTimeout (=> @closeAllTooltips()), 500

    dialogOpen: (options) ->
      @$('.dative-tasks-dialog').first().dialog 'open'

    dialogClose: (event) ->
      @$('.dative-tasks-dialog').first().dialog 'close'

    isOpen: -> @$('.dative-tasks-dialog').first().dialog 'isOpen'

    toggle: ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

    # A resource that wants to initiate a long-running task, should issue
    # `Backbone.trigger 'longRunningTaskPreflight', @model`. If the task can be
    # initiated, we pass `true` in the response event, otherwise we pass
    # `false`.
    longRunningTaskPreflight: (resourceModel, resourceId) ->
      longRunningTasks = @model.get 'longRunningTasks'
      tasksMaxedOut = longRunningTasks.length >=
        @model.get('longRunningTasksMax')
      taskAlreadyPending =
        resourceId in (t.resourceId for t in longRunningTasks)
      if tasksMaxedOut
        resourceModel.trigger 'preflightResponse', false, 'tasksMaxedOut'
      else if taskAlreadyPending
        resourceModel.trigger 'preflightResponse', false, 'taskAlreadyPending'
      else
        resourceModel.trigger 'preflightResponse', true

    # Poll a resource in order to see whether it's long-running task has
    # terminated. This polling assumes the following consistent API: a resource
    # has a `taskAttemptAttribute` that is a unique string that changes once
    # the long-running task has terminated. We poll the resource periodically
    # until the value of that resource changes.
    pollLongRunningTask: (taskObject) ->
      if @model.get('longRunningTasks').length >=
      @model.get('longRunningTasksMax')
        @model.trigger 'tooManyTasks'
        Backbone.trigger 'tooManyTasks'
      else
        @addTask taskObject
        taskObject.taskAttempt =
          taskObject.resourceModel.get(taskObject.taskAttemptAttribute)
        @poll taskObject

    disableGenerateAndCompileButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableGenerateAndCompileButton: ->
      @$("button.#{@buttonClass}").button 'enable'

    fetchResource: (taskObject) ->
      id = taskObject.resourceModel.get 'id'
      @listenToOnce taskObject.resourceModel,
        "fetch#{@utils.capitalize taskObject.resourceName}Success",
        @fetchResourceSuccess
      @listenToOnce taskObject.resourceModel,
        "fetch#{@utils.capitalize taskObject.resourceName}Fail",
        @fetchResourceFail
      taskObject.resourceModel.fetchResource id

    getTaskObject: (id) ->
      taskObjects = @model.get 'longRunningTasks'
      _.findWhere taskObjects, resourceId: id

    fetchResourceSuccess: (resourceObject) ->
      taskObject = @getTaskObject resourceObject.UUID
      taskModel = taskObject.resourceModel
      if resourceObject.compile_attempt is taskModel.get('compile_attempt')
        @poll taskObject
      else
        taskModel.set
          compile_succeeded: resourceObject.compile_succeeded
          compile_attempt: resourceObject.compile_attempt
          compile_message: resourceObject.compile_message
          datetime_modified: resourceObject.datetime_modified
          modifier: resourceObject.modifier
        if taskModel.get('compile_succeeded')
          Backbone.trigger("#{taskObject.resourceName}CompileSuccess",
            taskModel.get('compile_message'), taskModel.get('id'))
          taskModel.trigger 'trueGenerateAndCompileSuccess'
          taskObject.successful = true
        else
          Backbone.trigger("#{taskObject.resourceName}CompileFail",
            taskModel.get('compile_message'), taskModel.get('id'))
          taskModel.trigger 'trueGenerateAndCompileFail'
          taskObject.successful = false
        @removeTask taskObject

    addTask: (taskObject) ->
      longRunningTasks = @model.get 'longRunningTasks'
      longRunningTasksMax = @model.get 'longRunningTasksMax'
      longRunningTasks.push taskObject
      @model.save()
      @model.trigger 'change:longRunningTasks', @model, longRunningTasks
      Backbone.trigger 'change:longRunningTasks', longRunningTasks,
        longRunningTasksMax

    removeTask: (taskObject) ->
      longRunningTasks = @model.get 'longRunningTasks'
      longRunningTasksMax = @model.get 'longRunningTasksMax'
      longRunningTasksTerminated = @model.get 'longRunningTasksTerminated'
      longRunningTasks = _.without longRunningTasks, taskObject
      taskObject.taskEndTimestamp = new Date().getTime()
      longRunningTasksTerminated.push taskObject
      # FOX
      @model.set
        'longRunningTasks': longRunningTasks
        'longRunningTasksTerminated': longRunningTasksTerminated
      @model.save()
      @model.trigger 'change:longRunningTasks', @model, longRunningTasks
      Backbone.trigger 'change:longRunningTasks', longRunningTasks,
        longRunningTasksMax

    fetchResourceFail: (error, resourceModel) ->
      # TODO: remove the task object from the queue!
      taskObject = @getTaskObject resourceModel.get('UUID')
      taskModel = taskObject.resourceModel
      @removeTask taskObject
      Backbone.trigger "#{taskObject.resourceName}GenerateAndCompileFail",
        error, taskModel.get('id')
      taskModel.trigger 'trueGenerateAndCompileFail'

    poll: (taskObject) ->
      setTimeout((=> @fetchResource(taskObject)), 500)

