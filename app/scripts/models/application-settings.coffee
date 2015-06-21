define [
  'underscore'
  'backbone'
  './base'
  './server'
  './morphology'
  './../collections/servers'
  './../utils/utils'
  './../utils/globals'
  'FieldDB'
], (_, Backbone, BaseModel, ServerModel, MorphologyModel, ServersCollection,
  utils, globals, FieldDB) ->

  # Application Settings Model
  # --------------------------
  #
  # Holds server configuration and (in the future) other stuff.
  # Persisted in the browser using localStorage.
  #
  # Also contains the authentication logic.

  class ApplicationSettingsModel extends BaseModel

    modelClassName2model:
      'MorphologyModel': MorphologyModel

    initialize: ->
      fieldDBTempApp = new (FieldDB.App)(@get('fieldDBApplication'))
      fieldDBTempApp.authentication.eventDispatcher = Backbone
      @listenTo Backbone, 'authenticate:login', @authenticate
      @listenTo Backbone, 'authenticate:logout', @logout
      @listenTo Backbone, 'authenticate:register', @register
      @listenTo @, 'change:activeServer', @activeServerChanged
      if @get('activeServer')
        activeServer = @get 'activeServer'
        if activeServer instanceof ServerModel
          @listenTo activeServer, 'change:url', @activeServerURLChanged
      if not Modernizr.localstorage
        throw new Error 'localStorage unavailable in this browser, please upgrade.'

      @setVersion()

    # set app version from package.json
    setVersion: ->
      if @get('version') is 'da'
        $.ajax
          url: 'package.json',
          type: 'GET'
          dataType: 'json'
          error: (jqXHR, textStatus, errorThrown) =>
            console.log "Ajax request for package.json threw an error:
              #{errorThrown}"
          success: (packageDetails, textStatus, jqXHR) =>
            @set 'version', packageDetails.version

    activeServerChanged: ->
      #console.log 'active server has changed says the app settings model'
      if @get('fieldDBApplication')
        @get('fieldDBApplication').website = @get('activeServer').get('website')
        @get('fieldDBApplication').brand = @get('activeServer').get('brand') or
          @get('activeServer').get('userFriendlyServerName')
        @get('fieldDBApplication').brandLowerCase =
          @get('activeServer').get('brandLowerCase') or
            @get('activeServer').get('serverCode')

    activeServerURLChanged: ->
      #console.log 'active server URL has changed says the app settings model'

    getURL: ->
      url = @get('activeServer')?.get('url')
      if url.slice(-1) is '/' then url.slice(0, -1) else url

    getCorpusServerURL: ->
      @get('activeServer')?.get 'corpusUrl'

    getServerCode: ->
      @get('activeServer')?.get 'serverCode'

    authenticateAttemptDone: (taskId) ->
      Backbone.trigger 'longTask:deregister', taskId
      Backbone.trigger 'authenticate:end'


    # Login (a.k.a. authenticate)
    #=========================================================================

    # Attempt to authenticate with the passed-in credentials
    authenticate: (username, password) ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @authenticateFieldDBAuthService username: username, password: password, authUrl: @get('activeServer')?.get('url')
      else
        @authenticateOLD username: username, password: password

    authenticateOLD: (credentials) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      Backbone.trigger 'authenticateStart'
      @constructor.cors.request(
        method: 'POST'
        timeout: 20000
        url: "#{@getURL()}/login/authenticate"
        payload: credentials
        onload: (responseJSON) =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'authenticateEnd'
          if responseJSON.authenticated is true
            @set
              username: credentials.username
              password: credentials.password
              loggedIn: true
            @save()
            Backbone.trigger 'authenticateSuccess'
          else
            Backbone.trigger 'authenticateFail', responseJSON
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', responseJSON
          @authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', error: 'Request timed out'
          @authenticateAttemptDone taskId
      )

    authenticateFieldDBAuthService: (credentials) =>
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      Backbone.trigger 'authenticateStart'
      if not @get 'fieldDBApplication'
        @set 'fieldDBApplication', FieldDB.FieldDBObject.application
      @get('fieldDBApplication').authentication =
        @get('fieldDBApplication').authentication or new FieldDB.Authentication()
      @get('fieldDBApplication').authentication.login(credentials).then(
        (promisedResult) =>
          @set
            username: credentials.username,
            password: credentials.password, # TODO dont need this!
            loggedInUser: @get('fieldDBApplication').authentication.user
          @save()
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateSuccess'
          @authenticateAttemptDone taskId
      ,
        (error) =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', responseJSON.userFriendlyErrors
      ).fail (error) =>
        Backbone.trigger 'authenticateEnd'
        Backbone.trigger 'authenticateFail', error: 'Request timed out'
        @authenticateAttemptDone taskId

    # This is the to-be-deprecated version that has been made obsolete by
    # `authenticateFieldDBAuthService` above.
    authenticateFieldDBAuthService_: (credentials) =>
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      Backbone.trigger 'authenticateStart'
      @constructor.cors.request(
        method: 'POST'
        timeout: 20000
        url: "#{@getURL()}/login"
        payload: credentials
        onload: (responseJSON) =>
          if responseJSON.user
            # Remember the corpusServiceURL so we can logout.
            @get('activeServer')?.set(
              'corpusServerURL', @getFieldDBBaseDBURL(responseJSON.user))
            @set
              baseDBURL: @getFieldDBBaseDBURL(responseJSON.user)
              username: credentials.username,
              password: credentials.password,
              gravatar: responseJSON.user.gravatar,
              loggedInUser: responseJSON.user
            @save()
            credentials.name = credentials.username
            @authenticateFieldDBCorpusService credentials, taskId
          else
            Backbone.trigger 'authenticateFail', responseJSON.userFriendlyErrors
            @authenticateAttemptDone taskId
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', responseJSON
          @authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', error: 'Request timed out'
          @authenticateAttemptDone taskId
      )

    authenticateFieldDBCorpusService: (credentials, taskId) ->
      @constructor.cors.request(
        method: 'POST'
        timeout: 3000
        url: "#{@get('baseDBURL')}/_session"
        payload: credentials
        onload: (responseJSON) =>
          # TODO @jrwdunham: this responseJSON has a roles Array attribute which
          # references more corpora than I'm seeing from the `corpusteam`
          # request. Why the discrepancy?
          Backbone.trigger 'authenticateEnd'
          @authenticateAttemptDone taskId
          if responseJSON.ok
            @set
              loggedIn: true
              loggedInUserRoles: responseJSON.roles
            @save()
            Backbone.trigger 'authenticateSuccess'
          else
            Backbone.trigger 'authenticateFail', responseJSON
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', responseJSON
          @authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticateEnd'
          Backbone.trigger 'authenticateFail', error: 'Request timed out'
          @authenticateAttemptDone taskId
      )

    localStorageKey: 'dativeApplicationSettings'

    # An extremely simple re-implementation of `save`: we just JSON-ify the app
    # settings and store them in localStorage.
    save: ->
      localStorage.setItem @localStorageKey,
        JSON.stringify(@attributes)

    # Fetching means simply getting the app settings JSON object from
    # localStorage and setting it to the present model. Certain attributes are
    # evaluated to other Backbone models; handling this conversion is the job
    # of `backbonify`.
    fetch: (options) ->
      if localStorage.getItem @localStorageKey
        applicationSettingsObject =
          JSON.parse(localStorage.getItem(@localStorageKey))
        applicationSettingsObject = @backbonify applicationSettingsObject
        @set applicationSettingsObject
      else
        @save()

    # Logout
    #=========================================================================

    logout: ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @logoutFieldDB()
      else
        @logoutOLD()

    logoutOLD: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      Backbone.trigger 'logoutStart'
      @constructor.cors.request(
        url: "#{@getURL()}/login/logout"
        method: 'GET'
        timeout: 3000
        onload: (responseJSON) =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'logoutEnd'
          if responseJSON.authenticated is false
            @set 'loggedIn', false
            @save()
            Backbone.trigger 'logoutSuccess'
          else
            Backbone.trigger 'logoutFail'
        onerror: (responseJSON) =>
          Backbone.trigger 'logoutEnd'
          @authenticateAttemptDone taskId
          Backbone.trigger 'logoutFail'
        ontimeout: =>
          Backbone.trigger 'logoutEnd'
          @authenticateAttemptDone taskId
          Backbone.trigger 'logoutFail', error: 'Request timed out'
      )

    logoutFieldDB: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      Backbone.trigger 'logoutStart'
      if not @get 'fieldDBApplication'
        @set 'fieldDBApplication', FieldDB.FieldDBObject.application
      # TODO: @cesine: I'm getting "`authentication.logout` is not a function"
      # errors here ...
      @get('fieldDBApplication').authentication
        .logout({letClientHandleCleanUp: 'dontReloadWeNeedToCleanUpInDativeClient'})
        .then(
          (responseJSON) =>
            @set
              fieldDBApplication: null
              loggedIn: false
              activeFieldDBCorpus: null
              activeFieldDBCorpusTitle: null
            @save()
            Backbone.trigger 'logoutSuccess'
        ,
          (reason) ->
            Backbone.trigger 'logoutFail', reason.userFriendlyErrors.join ' '
      ).done(
        =>
          Backbone.trigger 'logoutEnd'
          @authenticateAttemptDone taskId
      )

    # Check if logged in
    #=========================================================================

    # Check if we are already logged in.
    checkIfLoggedIn: ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @checkIfLoggedInFieldDB()
      else
        @checkIfLoggedInOLD()

    checkIfLoggedInOLD: ->
      taskId = @guid()
      Backbone.trigger('longTask:register', 'checking if already logged in',
        taskId)
      @constructor.cors.request(
        url: "#{@getURL()}/speakers"
        timeout: 3000
        onload: (responseJSON) =>
          @authenticateAttemptDone(taskId)
          if utils.type(responseJSON) is 'array'
            @set 'loggedIn', true
            @save()
            Backbone.trigger 'authenticateSuccess'
          else
            @set 'loggedIn', false
            @save()
            Backbone.trigger 'authenticateFail'
        onerror: (responseJSON) =>
          @set 'loggedIn', false
          @save()
          Backbone.trigger 'authenticateFail', responseJSON
          @authenticateAttemptDone(taskId)
        ontimeout: =>
          @set 'loggedIn', false
          @save()
          Backbone.trigger 'authenticateFail', error: 'Request timed out'
          @authenticateAttemptDone(taskId)
      )

    checkIfLoggedInFieldDB: ->
      taskId = @guid()
      Backbone.trigger('longTask:register', 'checking if already logged in',
        taskId)
      FieldDB.Database::resumeAuthenticationSession().then(
        (sessionInfo) =>
          if sessionInfo.ok and sessionInfo.userCtx.name
            @set 'loggedIn', true
            @save()
            Backbone.trigger 'authenticateSuccess'
          else
            @set 'loggedIn', false
            @save()
            Backbone.trigger 'authenticateFail'
        ,
        (reason) =>
          @set 'loggedIn', false
          @save()
          Backbone.trigger 'authenticateFail', reason
      ).done(=> @authenticateAttemptDone taskId)


    # Register a new user
    # =========================================================================

    # `RegisterDialogView` should never allow an OLD registration attempt.
    register: (params) ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @registerFieldDB params

    registerFieldDB: (params) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'registering a new user', taskId
      params.authUrl = @getURL()
      params.appVersionWhenCreated = "v#{@get('version')}da"
      @constructor.cors.request(
        url: "#{@getURL()}/register"
        payload: params
        method: 'POST'
        timeout: 10000 # FieldDB auth can take some time to register a new user ...
        onload: (responseJSON) =>
          @authenticateAttemptDone taskId
          # TODO @cesine: what other kinds of responses to registration requests
          # can the auth service make?
          if responseJSON.user?
            user = responseJSON.user
            Backbone.trigger 'register:success', responseJSON
          else
            Backbone.trigger 'register:fail', responseJSON.userFriendlyErrors
        onerror: (responseJSON) =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'register:fail', 'server responded with error'
        ontimeout: =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'register:fail', 'Request timed out'
      )


    idAttribute: 'id'

    # Transform certain attribute values of the `appSetObj`
    # object into Backbone collections/models and return the `appSetObj`.
    backbonify: (appSetObj) ->
      serverModelsArray = ((new ServerModel(s)) for s in appSetObj.servers)
      appSetObj.servers = new ServersCollection(serverModelsArray)
      activeServer = appSetObj.activeServer
      appSetObj.activeServer = appSetObj.servers.get activeServer.id
      longRunningTasks = appSetObj.longRunningTasks
      for task in appSetObj.longRunningTasks
        task.resourceModel =
          new @modelClassName2model[task.modelClassName](task.resourceModel)
      for task in appSetObj.longRunningTasksTerminated
        task.resourceModel =
          new @modelClassName2model[task.modelClassName](task.resourceModel)
      appSetObj

    # Defaults
    #=========================================================================

    defaults: ->

      server1Object = new FieldDB.Connection(FieldDB.Connection.defaultConnection('localhost'))
      server1 =
        new ServerModel
          id: @guid()
          name: server1Object.userFriendlyServerName
          type: 'FieldDB'
          url: server1Object.authUrl
          serverCode: server1Object.serverLabel # should be "localhost"
          website: server1Object.website
          corpusServerURL: server1Object.corpusUrl

      server2 =
        new ServerModel
          id: @guid()
          name: 'OLD Local Development'
          type: 'OLD'
          url: 'http://127.0.0.1:5000'
          serverCode: null
          corpusServerURL: null
          website: 'http://www.onlinelinguisticdatabase.org'

      server3Object = new FieldDB.Connection(FieldDB.Connection.defaultConnection('lingsync'))
      server3 =
        new ServerModel
          id: @guid()
          name: server3Object.userFriendlyServerName
          type: 'FieldDB'
          url: server3Object.authUrl
          serverCode: server3Object.serverLabel
          corpusServerURL: server3Object.corpusUrl
          website: server3Object.website

      server4 =
        new ServerModel
          id: @guid()
          name: 'OLD'
          type: 'OLD'
          url: 'http://www.onlinelinguisticdatabase.org'
          serverCode: null
          corpusServerURL: null
          website: 'http://www.onlinelinguisticdatabase.org'

      if window.location.hostname in ["localhost", '127.0.0.1']
        servers = new ServersCollection([server1, server2, server3, server4])
      else
        servers = new ServersCollection([server3, server4])

      id: @guid()
      activeServer: servers.at 0
      loggedIn: false
      loggedInUser: null
      loggedInUserRoles: []
      baseDBURL: null
      username: ''
      password: '' # TODO trigger authenticate:mustconfirmidentity instead of storing the password in localStorage
      servers: servers
      serverTypes: ['FieldDB', 'OLD']
      fieldDBServerCodes: [
        'localhost'
        'testing'
        'beta'
        'production'
        'mcgill'
        'concordia'
        'dyslexdisorth'
      ]

      # TODO: remove the activeFieldDBCorpusTitle and related attributes. We
      # should simply store a real `CorpusModel` as the value of
      # `activeFieldDBCorpus`. Note that `AppView` adds
      # `activeFieldDBCorpusModel` and stores a Backbone model there. This all
      # needs to be cleaned up.
      activeFieldDBCorpus: null
      activeFieldDBCorpusTitle: null

      formsDisplaySettings:
        itemsPerPage: 10
        dataLabelsVisible: false
        allFormsExpanded: false

      subcorporaDisplaySettings:
        itemsPerPage: 10
        dataLabelsVisible: true
        allSubcorporaExpanded: false

      phonologiesDisplaySettings:
        itemsPerPage: 1
        dataLabelsVisible: true
        allPhonologiesExpanded: false

      morphologiesDisplaySettings:
        itemsPerPage: 1
        dataLabelsVisible: true
        allMorphologiesExpanded: false

      activeJQueryUITheme: 'pepper-grinder'
      defaultJQueryUITheme: 'pepper-grinder'
      jQueryUIThemes: [
        ['ui-lightness', 'UI lightness']
        ['ui-darkness', 'UI darkness']
        ['smoothness', 'Smoothness']
        ['start', 'Start']
        ['redmond', 'Redmond']
        ['sunny', 'Sunny']
        ['overcast', 'Overcast']
        ['le-frog', 'Le Frog']
        ['flick', 'Flick']
        ['pepper-grinder', 'Pepper Grinder']
        ['eggplant', 'Eggplant']
        ['dark-hive', 'Dark Hive']
        ['cupertino', 'Cupertino']
        ['south-street', 'South Street']
        ['blitzer', 'Blitzer']
        ['humanity', 'Humanity']
        ['hot-sneaks', 'Hot Sneaks']
        ['excite-bike', 'Excite Bike']
        ['vader', 'Vader']
        ['dot-luv', 'Dot Luv']
        ['mint-choc', 'Mint Choc']
        ['black-tie', 'Black Tie']
        ['trontastic', 'Trontastic']
        ['swanky-purse', 'Swanky Purse']
      ]

      # Use this to limit how many "long-running" tasks can be initiated from
      # within the app. A "long-running task" is a request to the server that
      # requires polling to know when it has terminated, e.g., phonology
      # compilation, morphology generation and compilation, etc.
      # NOTE !IMPORTANT: the OLD has a single foma worker and all requests to
      # compile FST-based resources appear to enter into a queue. This means
      # that a 3s request made while a 1h request is ongoing will take 1h1s!
      # Not good ...
      longRunningTasksMax: 2

      # An array of objects with keys `resourceName`, `taskName`,
      # `taskStartTimestamp`, and `taskPreviousUUID`.
      longRunningTasks: []

      # An array of objects with keys `resourceName`, `taskName`,
      # `taskStartTimestamp`, and `taskPreviousUUID`.
      longRunningTasksTerminated: []

      version: 'da'

      # These objects control how particular FieldDB form (i.e., datum) fields
      # are displayed. Note that FieldDB datumFields can be arbitrarily defined
      # by users so these fields may not all be present. This simply causes these
      # fields to be ordered (in both display and input views) as shown here,
      # if the fields exist. This will need to be made user-configurable and
      # corpus-specific in the future.
      fieldDBFormCategories:

        # This is the set of form attributes that are considered by Dative to
        # denote grammaticalities.
        grammaticality: [
          'judgement'
        ]

        # IGT FieldDB form attributes.
        # The returned array defines the "IGT" attributes of a FieldDB form (along
        # with their order). These are those that are aligned into columns of
        # one word each when displayed in an IGT view.
        igt: [
          'utterance'
          'morphemes'
          'gloss'
        ]

        # This is the set of form attributes that are considered by Dative to
        # denote a translation.
        translation: [
          'translation'
        ]

        # Secondary FieldDB form attributes.
        # The returned array defines the order of how the secondary attributes
        # are displayed. It is defined in models/application-settings because
        # it should ultimately be user-configurable.
        # QUESTION: @cesine: how is the elicitor of a FieldDB datum/session
        # documented?
        # TODO: `audioVideo`, `images`
        secondary: [
          'syntacticCategory'
          'comments'
          'tags'
          'dateElicited' # session field
          'language' # session field
          'dialect' # session field
          'consultants' # session field
          'enteredByUser'
          'dateEntered'
          'modifiedByUser'
          'dateModified'
          'syntacticTreeLatex'
          'validationStatus'
          'timestamp' # make this visible?
          'id'
        ]

        # These read-only fields will not be given input fields in add/update
        # interfaces.
        readonly: [
          'enteredByUser'
          'dateEntered'
          'modifiedByUser'
          'dateModified'
        ]

      # These objects are valuated by arrays that determine how OLD form fields
      # are displayed. Note that the OLD case is simpler than the FieldDB one
      # since the OLD data structure is (at present) fixed.
      oldFormCategories:

        grammaticality: [
          'grammaticality'
        ]

        # IGT OLD Form Attributes.
        igt: [
          'narrow_phonetic_transcription'
          'phonetic_transcription'
          'transcription'
          'morpheme_break'
          'morpheme_gloss'
        ]

        # Note: this is currently not being used (just being consistent with
        # FieldDB above.)
        translation: [
          'translations'
        ]

        # Secondary OLD Form Attributes.
        secondary: [
          'syntactic_category_string'
          'break_gloss_category'
          'comments'
          'speaker_comments'
          'elicitation_method'
          'tags'
          'syntactic_category'
          'date_elicited'
          'speaker'
          'elicitor'
          'enterer'
          'datetime_entered'
          'modifier'
          'datetime_modified'
          'verifier'
          'source'
          #'files'
          #'collections'
          'syntax'
          'semantics'
          'status'
          'UUID'
          'id'
        ]

        readonly: [
          'syntactic_category_string'
          'break_gloss_category'
          'enterer'
          'datetime_entered'
          'modifier'
          'datetime_modified'
          'UUID'
          'id'
        ]

