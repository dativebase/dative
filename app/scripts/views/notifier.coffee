define [
  './base'
  './notification'
  './../utils/globals'
  './../templates/notifier'
], (BaseView, NotificationView, globals, notifierTemplate) ->

  # Notifier
  # --------
  #
  # Handler for creating, displaying, hiding, and destroying notifications.

  class NotifierView extends BaseView

    template: notifierTemplate

    initialize: ->

      @crudResources = [
        'form'
        'subcorpus'
        'phonology'
        'morphology'
        'languageModel'
        'morphologicalParser'
      ]
      @crudRequests = ['add', 'update', 'destroy']
      @crudOutcomes = ['Success', 'Fail']
      @notifications = []
      @maxNotifications = 3
      @listenToEvents()

    listenToEvents: ->

      @listenTo Backbone, 'authenticateFail', @authenticateFail
      @listenTo Backbone, 'authenticateSuccess', @authenticateSuccess

      @listenTo Backbone, 'logoutFail', @logoutFail
      @listenTo Backbone, 'logoutSuccess', @logoutSuccess

      @listenTo Backbone, 'register:fail', @registerFail
      @listenTo Backbone, 'register:success', @registerSuccess

      @listenTo Backbone, 'fetchHistoryFormFail', @fetchHistoryFormFail
      @listenTo Backbone, 'fetchHistoryFormFailNoHistory',
        @fetchHistoryFormFailNoHistory

      @listenTo Backbone, 'newResourceOnLastPage', @newResourceOnLastPage

      @listenTo Backbone, 'morphologicalParseFail', @morphologicalParseFail
      @listenTo Backbone, 'morphologicalParseSuccess',
        @morphologicalParseSuccess
      @listenTo Backbone, 'morphologicalParserGenerateAndCompileFail',
        @morphologicalParserGenerateAndCompileFail
      @listenTo Backbone, 'morphologicalParserGenerateAndCompileSuccess',
        @morphologicalParserGenerateAndCompileSuccess

      @listenTo Backbone, 'phonologyApplyDownFail', @phonologyApplyDownFail
      @listenTo Backbone, 'phonologyApplyDownSuccess',
        @phonologyApplyDownSuccess
      @listenTo Backbone, 'phonologyCompileFail', @phonologyCompileFail
      @listenTo Backbone, 'phonologyCompileSuccess', @phonologyCompileSuccess
      @listenTo Backbone, 'phonologyRunTestsFail', @phonologyRunTestsFail
      @listenTo Backbone, 'phonologyRunTestsSuccess', @phonologyRunTestsSuccess

      @listenToCRUDResources()

    listenToCRUDResources: ->

      for resource in @crudResources
        for request in @crudRequests
          for outcome in @crudOutcomes
            event = "#{request}#{@utils.capitalize resource}#{outcome}"
            @listenTo Backbone, event, @[event]

    render: ->
      @$el.html @template()
      @

    renderNotification: (notification) ->
      @listenTo notification, 'notifierRendered', @closeOldNotifications
      @listenTo notification, 'destroySelf', @closeNotification
      @$('.notifications-container').append notification.render().el
      @rendered notification
      @notifications.push notification

    closeOldNotifications: ->
      while @notifications.length > @maxNotifications
        oldNotification = @notifications.shift()
        @closeNotification oldNotification

    closeNotification: (notification) ->
      notification.$el.slideUp()
      notification.close()
      @closed notification


    ############################################################################
    # Forms
    ############################################################################

    getFormId: (formModel) ->
      id = formModel.get 'id'
      activeServerType = globals
        .applicationSettings.get('activeServer').get 'type'
      if activeServerType is 'FieldDB' then id = id[-7..]
      id

    addFormSuccess: (formModel) ->
      notification = new NotificationView
        title: 'Form created'
        content: "You have successfully created a new form. Its id is
          #{@getFormId formModel}."
      @renderNotification notification

    updateFormSuccess: (formModel) ->
      notification = new NotificationView
        title: 'Form updated'
        content: "You have successfully updated form #{@getFormId formModel}."
      @renderNotification notification

    addUpdateFormFail: (error, type) ->
      if error
        content = "Your form #{type} request was unsuccessful. #{error}"
      else
        content = "Your form #{type} request was unsuccessful. See the error
          message(s) beneath the input fields."
      notification = new NotificationView
        title: "Form #{type} failed"
        content: content
        type: 'error'
      @renderNotification notification

    addFormFail: (error) ->
      @addUpdateFormFail error, 'creation'

    updateFormFail: (error) ->
      @addUpdateFormFail error, 'update'

    destroyFormFail: (error) ->
      notification = new NotificationView
        title: 'Form deletion failed'
        content: "Your form creation request was unsuccessful. #{error}"
        type: 'error'
      @renderNotification notification

    destroyFormSuccess: (formModel) ->
      notification = new NotificationView
        title: 'Form deleted'
        content: "You have successfully deleted the form with id
          #{@getFormId formModel}."
      @renderNotification notification


    ############################################################################
    # Subcorpora: add, update, & destroy notifications
    ############################################################################

    addSubcorpusSuccess: (model) -> @addResourceSuccess model, 'subcorpus'
    addSubcorpusFail: (error) -> @addResourceFail error, 'subcorpus'
    updateSubcorpusSuccess: (model) -> @updateResourceSuccess model, 'subcorpus'
    updateSubcorpusFail: (error) -> @updateResourceFail error, 'subcorpus'
    destroySubcorpusFail: (error) -> @destroyResourceFail error, 'subcorpus'
    destroySubcorpusSuccess: (model) ->
      @destroyResourceSuccess model, 'subcorpus'

    ############################################################################
    # Phonologies: add, update, & destroy notifications
    ############################################################################

    addPhonologySuccess: (model) -> @addResourceSuccess model, 'phonology'
    addPhonologyFail: (error) -> @addResourceFail error, 'phonology'
    updatePhonologySuccess: (model) -> @updateResourceSuccess model, 'phonology'
    updatePhonologyFail: (error) -> @updateResourceFail error, 'phonology'
    destroyPhonologyFail: (error) -> @destroyResourceFail error, 'phonology'
    destroyPhonologySuccess: (model) ->
      @destroyResourceSuccess model, 'phonology'

    ############################################################################
    # Morphologies: add, update, & destroy notifications
    ############################################################################

    addMorphologySuccess: (model) -> @addResourceSuccess model, 'morphology'
    addMorphologyFail: (error) -> @addResourceFail error, 'morphology'
    updateMorphologySuccess: (model) ->
      @updateResourceSuccess model, 'morphology'
    updateMorphologyFail: (error) -> @updateResourceFail error, 'morphology'
    destroyMorphologyFail: (error) -> @destroyResourceFail error, 'morphology'
    destroyMorphologySuccess: (model) ->
      @destroyResourceSuccess model, 'morphology'

    ############################################################################
    # Language models: add, update, & destroy notifications
    ############################################################################

    addLanguageModelSuccess: (model) ->
      @addResourceSuccess model, 'language model'
    addLanguageModelFail: (error) ->
      @addResourceFail error, 'language model'
    updateLanguageModelSuccess: (model) ->
      @updateResourceSuccess model, 'language model'
    updateLanguageModelFail: (error) ->
      @updateResourceFail error, 'language model'
    destroyLanguageModelFail: (error) ->
      @destroyResourceFail error, 'language model'
    destroyLanguageModelSuccess: (model) ->
      @destroyResourceSuccess model, 'language model'

    ############################################################################
    # Morphological parsers: add, update, & destroy notifications
    ############################################################################

    addMorphologicalParserSuccess: (model) ->
      @addResourceSuccess model, 'morphological parser'
    addMorphologicalParserFail: (error) ->
      @addResourceFail error, 'morphological parser'
    updateMorphologicalParserSuccess: (model) ->
      @updateResourceSuccess model, 'morphological parser'
    updateMorphologicalParserFail: (error) ->
      @updateResourceFail error, 'morphological parser'
    destroyMorphologicalParserFail: (error) ->
      @destroyResourceFail error, 'morphological parser'
    destroyMorphologicalParserSuccess: (model) ->
      @destroyResourceSuccess model, 'morphological parser'

    ############################################################################
    # Resources: add, update, & destroy notifications
    ############################################################################

    addResourceSuccess: (model, resource) ->
      notification = new NotificationView
        title: "#{@utils.capitalize resource} created"
        content: "You have successfully created a new #{resource}. Its id is
          #{model.get 'id'}."
      @renderNotification notification

    updateResourceSuccess: (model, resource) ->
      notification = new NotificationView
        title: "#{@utils.capitalize resource} updated"
        content: "You have successfully updated #{resource} #{model.get 'id'}."
      @renderNotification notification

    addUpdateResourceFail: (error, type, resource) ->
      if error
        content = "Your #{resource} #{type} request was unsuccessful. #{error}"
      else
        content = "Your #{resource} #{type} request was unsuccessful. See the
          error message(s) beneath the input fields."
      notification = new NotificationView
        title: "#{@utils.capitalize resource} #{type} failed"
        content: content
        type: 'error'
      @renderNotification notification

    addResourceFail: (error, resource) ->
      @addUpdateResourceFail error, 'creation', resource

    updateResourceFail: (error, resource) ->
      @addUpdateResourceFail error, 'update', resource

    destroyResourceFail: (error, resource) ->
      notification = new NotificationView
        title: "#{@utils.capitalize resource} deletion failed"
        content: "Your #{resource} deletion request was unsuccessful. #{error}"
        type: 'error'
      @renderNotification notification

    destroyResourceSuccess: (model, resource) ->
      notification = new NotificationView
        title: "#{@utils.capitalize resource} deleted"
        content: "You have successfully deleted the #{resource} with id
          #{model.get 'id'}."
      @renderNotification notification

    fetchHistoryFormFail: (formModel) ->
      notification = new NotificationView
        title: "Form history fetch failed"
        content: "Unable to fetch the history of form #{formModel.id}"
        type: 'error'
      @renderNotification notification

    fetchHistoryFormFailNoHistory: (formModel) ->
      notification = new NotificationView
        title: "No history"
        content: "There are no previous versions for form #{formModel.id}"
        type: 'warning'
      @renderNotification notification

    newResourceOnLastPage: (resourceModel, resourceName) ->
      notification = new NotificationView
        title: "New #{resourceName} on last page"
        content: "The #{resourceName} that you just created can be viewed on the last page"
        type: 'warning'
      @renderNotification notification

    morphologicalParseFail: (error, parserId) ->
      notification = new NotificationView
        title: "Parse fail"
        content: "Your attempt to parse using morphological parser #{parserId}
          failed: #{error}"
        type: 'error'
      @renderNotification notification

    morphologicalParseSuccess: (parserId) ->
      notification = new NotificationView
        title: "Parse success"
        content: "Your attempt to parse using morphological parser #{parserId}
          was successful; see the parses below the word input field."
      @renderNotification notification

    morphologicalParserGenerateAndCompileFail: (error, parserId) ->
      notification = new NotificationView
        title: "Parser generate and compile fail"
        content: "Your attempt to generate and compile parser #{parserId}
          failed: #{error}"
        type: 'error'
      @renderNotification notification

    morphologicalParserGenerateAndCompileSuccess: (parserId) ->
      notification = new NotificationView
        title: "Parser generate and compile success"
        content: "Your attempt to generate and compile the morphological parser
          #{parserId} was successful"
      @renderNotification notification

    phonologyCompileFail: (error, phonologyId) ->
      notification = new NotificationView
        title: "Phonology compile fail"
        content: "Your attempt to compile phonology #{phonologyId}
          failed: #{error}"
        type: 'error'
      @renderNotification notification

    phonologyCompileSuccess: (message, phonologyId) ->
      notification = new NotificationView
        title: "Phonology compile success"
        content: "Your attempt to compile phonology #{phonologyId} was
          successful: #{message}"
      @renderNotification notification

    phonologyApplyDownFail: (error, phonologyId) ->
      notification = new NotificationView
        title: "Phonologize fail"
        content: "Your attempt to phonologize using phonology #{phonologyId}
          failed: #{error}"
        type: 'error'
      @renderNotification notification

    phonologyApplyDownSuccess: (phonologyId) ->
      notification = new NotificationView
        title: "Phonologize success"
        content: "Your attempt to phonologize using phonology #{phonologyId}
          was successful; see the surface forms below the word input field."
      @renderNotification notification

    phonologyRunTestsFail: (error, phonologyId) ->
      notification = new NotificationView
        title: "Run tests fail"
        content: "Your attempt to run the tests of phonology #{phonologyId}
          was not successful: #{error}"
        type: 'error'
      @renderNotification notification

    phonologyRunTestsSuccess: (phonologyId) ->
      notification = new NotificationView
        title: "Run tests success"
        content: "Your attempt to run the tests of phonology #{phonologyId}
          was successful; see the results in the table below the “Run
          Tests” button."
      @renderNotification notification

    registerFail: (reason) ->
      notification = new NotificationView
        title: 'Register failed'
        content: "Your attempt to register was unsuccessful. #{reason}"
        type: 'error'
      @renderNotification notification

    registerSuccess: ->
      notification = new NotificationView
        title: 'Registered'
        content: 'You have successfully created a new account'
      @renderNotification notification

    authenticateFail: (errorObj) ->
      notification = new NotificationView
        title: 'Login failed'
        content: @getAuthenticateFailContent errorObj
        type: 'error'
      @renderNotification notification

    authenticateSuccess: ->
      notification = new NotificationView
        title: 'Logged in'
        content: 'You have successfully logged in.'
      @renderNotification notification

    logoutFail: ->
      notification = new NotificationView
        title: 'Logout failed'
        content: 'Your attempt to log out was unsuccessful.'
        type: 'error'
      @renderNotification notification

    logoutSuccess: ->
      notification = new NotificationView
        title: 'Logged out'
        content: 'You have successfully logged out.'
      @renderNotification notification

    getAuthenticateFailContent: (errorObj) ->
      contentPrefix = 'Yor attempt to log in was unsuccessful.'
      if errorObj
        if @getActiveServerType() is 'OLD'
          if errorObj.error
            "#{contentPrefix} #{errorObj.error}"
          else
            contentPrefix
        else
          if @utils.type(errorObj) is 'object' # FieldDB API returns string, not object (always?)
            if errorObj.reason
              "#{contentPrefix} #{errorObj.reason}"
            else
              contentPrefix
          else
            "#{contentPrefix} #{errorObj}"
      else
        contentPrefix

