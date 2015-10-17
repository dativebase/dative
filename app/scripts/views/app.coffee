define [
  'backbone'
  'FieldDB'
  './../routes/router'
  './base'
  './resource'
  './mainmenu'
  './notifier'
  './login-dialog'
  './register-dialog'
  './alert-dialog'
  './tasks-dialog'
  './help-dialog'
  './resource-displayer-dialog'
  './exporter-dialog'
  './home'

  './application-settings'
  './collections'
  './corpora'
  './elicitation-methods'
  './files'
  './forms'
  './language-models'
  './languages'
  './morphological-parsers'
  './morphologies'
  './orthographies'
  './pages'
  './phonologies'
  './searches'
  './sources'
  './speakers'
  './subcorpora'
  './syntactic-categories'
  './tags'
  './users'

  './collection'
  './elicitation-method'
  './file'
  './form'
  './language-model'
  './language'
  './morphological-parser'
  './morphology'
  './orthography'
  './page'
  './phonology'
  './search'
  './source'
  './speaker'
  './subcorpus'
  './syntactic-category'
  './tag'
  './user-old-circular'

  './../models/application-settings'
  './../models/collection'
  './../models/elicitation-method'
  './../models/file'
  './../models/form'
  './../models/language-model'
  './../models/language'
  './../models/morphological-parser'
  './../models/morphology'
  './../models/orthography'
  './../models/page'
  './../models/phonology'
  './../models/search'
  './../models/source'
  './../models/speaker'
  './../models/subcorpus'
  './../models/syntactic-category'
  './../models/tag'
  './../models/user-old'

  './../collections/collections'
  './../collections/elicitation-methods'
  './../collections/files'
  './../collections/forms'
  './../collections/language-models'
  './../collections/languages'
  './../collections/morphological-parsers'
  './../collections/morphologies'
  './../collections/orthographies'
  './../collections/pages'
  './../collections/phonologies'
  './../collections/searches'
  './../collections/sources'
  './../collections/speakers'
  './../collections/subcorpora'
  './../collections/syntactic-categories'
  './../collections/tags'
  './../collections/users'

  './../utils/globals'
  './../templates/app'
], (Backbone, FieldDB, Workspace, BaseView, ResourceView, MainMenuView,
  NotifierView, LoginDialogView, RegisterDialogView, AlertDialogView,
  TasksDialogView, HelpDialogView, ResourceDisplayerDialogView,
  ExporterDialogView, HomePageView,

  ApplicationSettingsView, CollectionsView, CorporaView,
  ElicitationMethodsView, FilesView, FormsView, LanguageModelsView,
  LanguagesView, MorphologicalParsersView, MorphologiesView, OrthographiesView,
  PagesView, PhonologiesView, SearchesView, SourcesView, SpeakersView,
  SubcorporaView, SyntacticCategoriesView, TagsView, UsersView,

  CollectionView, ElicitationMethodView, FileView, FormView, LanguageModelView,
  LanguageView, MorphologicalParserView, MorphologyView, OrthographyView,
  PageView, PhonologyView, SearchView, SourceView, SpeakerView, SubcorpusView,
  SyntacticCategoryView, TagView, UserView,

  ApplicationSettingsModel, CollectionModel, ElicitationMethodModel, FileModel,
  FormModel, LanguageModelModel, LanguageModel, MorphologicalParserModel,
  MorphologyModel, OrthographyModel, PageModel, PhonologyModel, SearchModel,
  SourceModel, SpeakerModel, SubcorpusModel, SyntacticCategoryModel, TagModel,
  UserModel,

  CollectionsCollection, ElicitationMethodsCollection, FilesCollection,
  FormsCollection, LanguageModelsCollection, LanguagesCollection,
  MorphologicalParsersCollection, MorphologiesCollection,
  OrthographiesCollection, PagesCollection, PhonologiesCollection,
  SearchesCollection, SourcesCollection, SpeakersCollection,
  SubcorporaCollection, SyntacticCategoriesCollection, TagsCollection,
  UsersCollection,

  globals, appTemplate) ->


  # App View
  # --------
  #
  # This is the spine of the application. Only one AppView object is created
  # and it controls the creation and rendering of all of the subviews that
  # control the content in the body of the page.

  class AppView extends BaseView

    template: appTemplate
    el: '#dative-client-app'

    initialize: (options) ->
      @getApplicationSettings options
      globals.applicationSettings = @applicationSettings
      @overrideFieldDBNotificationHooks()
      @initializePersistentSubviews()
      @resourceModel = null # this and the next attribute are for displaying a single resource in the main page.
      @resourcesCollection = null
      @router = new Workspace
        resources: @myResources
        mainMenuView: @mainMenuView
      @listenToEvents()
      @render()
      @setTheme()
      Backbone.history.start()
      @showHomePageView()

    events:
      'click': 'bodyClicked'

    render: ->
      if window.location.hostname is ['localhost', '127.0.0.1']
        setTimeout ->
          console.clear()
        , 2000
      @$el.html @template()
      @renderPersistentSubviews()
      @matchWindowDimensions()
      @

    listenToEvents: ->
      @listenTo @mainMenuView, 'request:home', @showHomePageView
      @listenTo @mainMenuView, 'request:openLoginDialogBox', @toggleLoginDialog
      @listenTo @mainMenuView, 'request:toggleHelpDialogBox', @toggleHelpDialog
      @listenTo @mainMenuView, 'request:toggleTasksDialog', @toggleTasksDialog
      @listenTo @mainMenuView, 'request:openRegisterDialogBox',
        @toggleRegisterDialog

      @listenTo @router, 'route:home', @showHomePageView
      @listenTo @router, 'route:openLoginDialogBox', @toggleLoginDialog
      @listenTo @router, 'route:openRegisterDialogBox', @toggleRegisterDialog

      @listenTo @loginDialog, 'request:openRegisterDialogBox',
        @toggleRegisterDialog
      @listenTo Backbone, 'loginSuggest', @openLoginDialogWithDefaults
      @listenTo Backbone, 'authenticateSuccess', @authenticateSuccess
      @listenTo Backbone, 'authenticate:mustconfirmidentity',
        @authenticateConfirmIdentity
      @listenTo Backbone, 'logoutSuccess', @logoutSuccess
      @listenTo Backbone, 'useFieldDBCorpus', @useFieldDBCorpus
      @listenTo Backbone, 'applicationSettings:changeTheme', @changeTheme
      @listenTo Backbone, 'showResourceInDialog', @showResourceInDialog
      @listenTo Backbone, 'showResourceModelInDialog',
        @showResourceModelInDialog
      @listenTo Backbone, 'openExporterDialog', @openExporterDialog
      @listenTo Backbone, 'routerNavigateRequest', @routerNavigateRequest
      @listenToResources()

    routerNavigateRequest: (route) -> @router.navigate route

    # Listen for resource-related events. The resources and relevant events
    # are configured by the `@myResources` object.
    # TODO/QUESTION: why not just listen on the resources subclass instead of
    # on Backbone with all of this complex naming stuff?
    listenToResources: ->
      for resource, config of @myResources
        do =>
          resourceName = resource
          resourcePlural = @utils.pluralize resourceName
          resourceCapitalized = @utils.capitalize resourceName
          resourcePluralCapitalized = @utils.capitalize resourcePlural
          @listenTo Backbone, "destroy#{resourceCapitalized}Success",
            (resourceModel) => @destroyResourceSuccess resourceModel
          @listenTo Backbone, "#{resourcePlural}View:showAllLabels",
            => @changeDisplaySetting resourcePlural, 'dataLabelsVisible', true
          @listenTo Backbone, "#{resourcePlural}View:hideAllLabels",
            =>
              @changeDisplaySetting resourcePlural, 'dataLabelsVisible', false
          @listenTo Backbone,
            "#{resourcePlural}View:expandAll#{resourcePluralCapitalized}",
            =>
              @changeDisplaySetting resourcePlural,
                "all#{resourcePluralCapitalized}Expanded", true
          @listenTo Backbone,
            "#{resourcePlural}View:collapseAll#{resourcePluralCapitalized}",
            =>
              @changeDisplaySetting resourcePlural,
                "all#{resourcePluralCapitalized}Expanded", false
          @listenTo Backbone, "#{resourcePlural}View:itemsPerPageChange",
            (newItemsPerPage) =>
              @changeDisplaySetting resourcePlural, 'itemsPerPage',
                newItemsPerPage
          @listenTo @mainMenuView, "request:#{resourcePlural}Browse",
            (options={}) => @showResourcesView resourceName, options
          @listenTo @mainMenuView, "request:#{resourceName}Add",
            => @showNewResourceView resourceName
          if config.params?.searchable is true
            @listenTo Backbone, "request:#{resourcePlural}BrowseSearchResults",
              (options={}) => @showResourcesView resourceName, options
          if config.params?.corpusElement is true
            @listenTo Backbone, "request:#{resourcePlural}BrowseCorpus",
              (options={}) => @showResourcesView resourceName, options
          @listenTo Backbone, "request:#{resourceCapitalized}View",
            (id) => @showResourceView(resourceName, id)

    initializePersistentSubviews: ->
      @mainMenuView = new MainMenuView model: @applicationSettings
      @loginDialog = new LoginDialogView model: @applicationSettings
      @registerDialog = new RegisterDialogView model: @applicationSettings
      @alertDialog = new AlertDialogView model: @applicationSettings
      @tasksDialog = new TasksDialogView model: @applicationSettings
      @helpDialog = new HelpDialogView()
      @notifier = new NotifierView(@myResources)
      @exporterDialog = new ExporterDialogView()
      @getResourceDisplayerDialogs()

    renderPersistentSubviews: ->
      @mainMenuView.setElement(@$('#mainmenu')).render()
      @loginDialog.setElement(@$('#login-dialog-container')).render()
      @registerDialog.setElement(@$('#register-dialog-container')).render()
      @alertDialog.setElement(@$('#alert-dialog-container')).render()
      @tasksDialog.setElement(@$('#tasks-dialog-container')).render()
      @helpDialog.setElement(@$('#help-dialog-container'))
      @renderResourceDisplayerDialogs()
      @notifier.setElement(@$('#notifier-container')).render()
      @exporterDialog.setElement(@$('#exporter-dialog-container')).render()

      @rendered @mainMenuView
      @rendered @loginDialog
      @rendered @registerDialog
      @rendered @alertDialog
      @rendered @tasksDialog
      @rendered @notifier
      @rendered @exporterDialog

    renderHelpDialog: ->
      @helpDialog.render()
      @rendered @helpDialog

    bodyClicked: ->
      Backbone.trigger 'bodyClicked' # Mainmenu superclick listens for this

    useFieldDBCorpus: (dbname) ->
      currentlyActiveFieldDBCorpus = @activeFieldDBCorpus
      fieldDBCorporaCollection = @corporaView?.collection
      @activeFieldDBCorpus = fieldDBCorporaCollection?.findWhere
        dbname: dbname
      @applicationSettings.save
        'activeFieldDBCorpus': dbname
        'activeFieldDBCorpusTitle': @activeFieldDBCorpus.get 'title'
        'activeFieldDBCorpusModel': @activeFieldDBCorpus # TODO: FIX THIS ABERRATION!
      globals.activeFieldDBCorpus = @activeFieldDBCorpus
      if currentlyActiveFieldDBCorpus is @activeFieldDBCorpus
        @showFormsView fieldDBCorpusHasChanged: false
      else
        # @mainMenuView.activeFieldDBCorpusChanged @activeFieldDBCorpus.get('title')
        @showFormsView fieldDBCorpusHasChanged: true

    logoutSuccess: ->
      @closeVisibleView()
      @corporaView = null
      @usersView = null # TODO: all of these collection views should be DRY-ly emptied upon logout ...
      @showHomePageView()

    activeServerType: ->
      try
        @applicationSettings.get('activeServer').get 'type'
      catch
        null

    authenticateSuccess: ->
      activeServerType = @activeServerType()
      switch activeServerType
        when 'FieldDB'
          if @applicationSettings.get('fieldDBApplication') isnt
          FieldDB.FieldDBObject.application
            @applicationSettings.set 'fieldDBApplication',
              FieldDB.FieldDBObject.application
          @showCorporaView()
        when 'OLD' then @showFormsView()
        else console.log 'Error: you logged in to a non-FieldDB/non-OLD server
          (?).'

    authenticateConfirmIdentity: (message) =>
      message = message or 'We need to make sure this is you. Confirm your
        password to continue.'
      if not @originalMessage then @originalMessage = message
      @displayConfirmIdentityDialog(
          message
        ,
          (loginDetails) =>
            console.log 'no problem.. can keep working'
            fieldDBApplication = @applicationSettings.get('fieldDBApplication')
            @set
              username: fieldDBApplication.authentication.user.username,
              loggedInUser: fieldDBApplication.authentication.user
            @save()
            delete @originalMessage
        ,
          (loginDetails) =>
            if @confirmIdentityErrorCount > 3
              console.log ' In this case of confirming identity, the user MUST
                authenticate. If they cant remember their password, after 4
                attempts, log them out.'
              delete @originalMessage
              Backbone.trigger 'authenticate:logout'
            console.log 'Asking again'
            @confirmIdentityErrorCount = @confirmIdentityErrorCount or 0
            @confirmIdentityErrorCount += 1
            @authenticateConfirmIdentity "#{@originalMessage}
              #{loginDetails.userFriendlyErrors.join ' '}"
      )

    # Set `@applicationSettings`
    getApplicationSettings: (options) ->
      # Allowing an app settings model in the options facilitates testing.
      if options?.applicationSettings
        @applicationSettings = options.applicationSettings
      else
        @applicationSettings = new ApplicationSettingsModel()
        @applicationSettings.fetch()

    # Size the #appview div relative to the window size
    matchWindowDimensions: ->
      @$('#appview').css height: $(window).height() - 50
      $(window).resize =>
        @$('#appview').css height: $(window).height() - 50

    renderVisibleView: (taskId=null) ->
      if (@visibleView instanceof ResourceView)
        @$('#appview')
          .css 'overflow-y', 'scroll'
          .html @visibleView.render().el
      else
        $appView = @$ '#appview'
        $appView.css 'overflow-y', 'initial'
        @visibleView.setElement $appView
        @visibleView.render taskId
      @rendered @visibleView

    closeVisibleView: -> if @visibleView then @closeView @visibleView

    loggedIn: ->
      if @applicationSettings.get('fieldDBApplication')
        fieldDBApp = @applicationSettings.get 'fieldDBApplication'
        if fieldDBApp.authentication and fieldDBApp.authentication.user and
        fieldDBApp.authentication.user.authenticated
          @applicationSettings.set 'loggedIn', true
          @applicationSettings.set 'loggedInUserRoles',
            fieldDBApp.authentication.user.roles
      @applicationSettings.get 'loggedIn'

    showHomePageView: ->
      if @homePageView and @visibleView is @homePageView then return
      @router.navigate 'home'
      @closeVisibleView()
      if not @homePageView then @homePageView = new HomePageView()
      @visibleView = @homePageView
      @renderVisibleView()

    ############################################################################
    # Show resources view machinery
    ############################################################################

    # Render (and perhaps instantiate) a view over a collection of resources.
    # This method works in conjunction with the metadata in the `@myResources`
    # object; CRUCIALLY, only resources with an attribute in that object can be
    # shown using this method. The simplest case is to call this method with
    # the singular camelCase name of a resource as its first argument; e.g.,
    # `@showResourcesView 'elicitationMethod'`.
    showResourcesView: (resourceName, options={}) ->
      o = @showResourcesViewSetDefaultOptions resourceName, options
      names = @getResourceNames resourceName
      myViewAttr = "#{names.plural}View"
      if o.authenticationRequired and not @loggedIn() then return
      if o.searchable and o.search
        @closeVisibleView()
        @visibleView = null
      if @[myViewAttr] and @visibleView is @[myViewAttr] then return
      @router.navigate names.hypPlur
      taskId = @guid()
      Backbone.trigger 'longTask:register', "Opening #{names.regPlur} view",
        taskId
      @closeVisibleView()
      if @[myViewAttr]
        if @fieldDBCorpusHasChanged(myViewAttr, o)
          @closeView @[myViewAttr]
          @[myViewAttr] = @instantiateResourcesView resourceName, o
      else
        @[myViewAttr] = @instantiateResourcesView resourceName, o
      @visibleView = @[myViewAttr]
      @showNewResourceViewOption o
      @searchableOption o
      @corpusElementOption o
      @renderVisibleView taskId

    # Show the resource of type `resourceName` with id `id` in the main page of
    # the application. This is what happens when you navigate to, e.g.,
    # /#form/123.
    showResourceView: (resourceName, resourceId, options={}) ->
      o = @showResourceViewSetDefaultOptions resourceName, options
      names = @getResourceNames resourceName
      myViewAttr = "#{resourceName}View"
      if o.authenticationRequired and not @loggedIn() then return
      if @[myViewAttr] and @visibleView is @[myViewAttr] then return
      @router.navigate "#{names.hyphen}/#{resourceId}"
      @closeVisibleView()
      @resourcesCollection =
        new @myResources[resourceName].resourcesCollectionClass()
      if @resourceModel then @stopListening @resourceModel
      @resourceModel = new @myResources[resourceName].resourceModelClass(
        {}, {collection: @resourcesCollection})
      # We have to listen and fetch here, which is different from
      # `ResourcesView` sub-classes, which fetch their collections post-render.
      @listenToOnce @resourceModel, "fetch#{names.capitalized}Fail",
        @fetchResourceFail
      @listenToOnce @resourceModel, "fetch#{names.capitalized}Success",
        (resourceObject) =>
          @fetchResourceSuccess resourceName, myViewAttr, resourceObject
      @resourceModel.fetchResource resourceId

    # We failed to fetch the resource model data from the server.
    fetchResourceFail: (error, resourceModel) ->
      console.log "Failed to fetch the following resource ..."
      console.log error
      console.log resourceModel

    # We succeeded in fetching the resource model data from the server,
    # so we render a `ResourceView` subclass for it.
    fetchResourceSuccess: (resourceName, myViewAttr, resourceObject) ->
      @resourceModel.set resourceObject
      @[myViewAttr] = new @myResources[resourceName].resourceViewClass
        model: @resourceModel
        dataLabelsVisible: true
        expanded: true
      @visibleView = @[myViewAttr]
      @renderVisibleView()

    # We heard that a resource was destroyed. If the destroyed resource is the
    # one that we are currently displaying, then we hide it, close it, and
    # navigate to the home page.
    destroyResourceSuccess: (resourceModel) ->
      if @visibleView and
      @visibleView.model is @resourceModel and
      resourceModel.get('id') is @resourceModel.get('id') and
      resourceModel instanceof @resourceModel.constructor
        @visibleView.$el.slideUp
          complete: =>
            @closeVisibleView()
            @showHomePageView()

    # The information in this object controls how `@showResourcesView` behaves.
    # The `resourceName` param of that method must be an attribute of this
    # object. NOTE: default params not supplied here are filled in by
    # `@showResourcesViewSetDefaultOptions`.
    myResources:

      applicationSetting:
        resourcesViewClass: ApplicationSettingsView
        resourceViewClass: null
        resourceModelClass: null
        resourcesCollectionClass: null
        params:
          authenticationRequired: false
          needsAppSettings: true

      collection:
        resourcesViewClass: CollectionsView
        resourceViewClass: CollectionView
        resourceModelClass: CollectionModel
        resourcesCollectionClass: CollectionsCollection
        params:
          searchable: true

      corpus:
        resourcesViewClass: CorporaView
        resourceViewClass: null
        resourceModelClass: null
        resourcesCollectionClass: null
        params:
          needsAppSettings: true
          needsActiveFieldDBCorpus: true

      elicitationMethod:
        resourcesViewClass: ElicitationMethodsView
        resourceViewClass: ElicitationMethodView
        resourceModelClass: ElicitationMethodModel
        resourcesCollectionClass: ElicitationMethodsCollection

      file:
        resourcesViewClass: FilesView
        resourceViewClass: FileView
        resourceModelClass: FileModel
        resourcesCollectionClass: FilesCollection
        params:
          searchable: true

      form:
        resourcesViewClass: FormsView
        resourceViewClass: FormView
        resourceModelClass: FormModel
        resourcesCollectionClass: FormsCollection
        params:
          needsAppSettings: true
          searchable: true
          corpusElement: true
          needsActiveFieldDBCorpus: true

      languageModel:
        resourcesViewClass: LanguageModelsView
        resourceViewClass: LanguageModelView
        resourceModelClass: LanguageModelModel
        resourcesCollectionClass: LanguageModelsCollection

      language:
        resourcesViewClass: LanguagesView
        resourceViewClass: LanguageView
        resourceModelClass: LanguageModel
        resourcesCollectionClass: LanguagesCollection
        params:
          searchable: true

      morphologicalParser:
        resourcesViewClass: MorphologicalParsersView
        resourceViewClass: MorphologicalParserView
        resourceModelClass: MorphologicalParserModel
        resourcesCollectionClass: MorphologicalParsersCollection

      morphology:
        resourcesViewClass: MorphologiesView
        resourceViewClass: MorphologyView
        resourceModelClass: MorphologyModel
        resourcesCollectionClass: MorphologiesCollection

      orthography:
        resourcesViewClass: OrthographiesView
        resourceViewClass: OrthographyView
        resourceModelClass: OrthographyModel
        resourcesCollectionClass: OrthographiesCollection

      page:
        resourcesViewClass: PagesView
        resourceViewClass: PageView
        resourceModelClass: PageModel
        resourcesCollectionClass: PagesCollection

      phonology:
        resourcesViewClass: PhonologiesView
        resourceViewClass: PhonologyView
        resourceModelClass: PhonologyModel
        resourcesCollectionClass: PhonologiesCollection

      search:
        resourcesViewClass: SearchesView
        resourceViewClass: SearchView
        resourceModelClass: SearchModel
        resourcesCollectionClass: SearchesCollection
        params:
          searchable: true

      source:
        resourcesViewClass: SourcesView
        resourceViewClass: SourceView
        resourceModelClass: SourceModel
        resourcesCollectionClass: SourcesCollection
        params:
          searchable: true

      speaker:
        resourcesViewClass: SpeakersView
        resourceViewClass: SpeakerView
        resourceModelClass: SpeakerModel
        resourcesCollectionClass: SpeakersCollection

      subcorpus:
        resourcesViewClass: SubcorporaView
        resourceViewClass: SubcorpusView
        resourceModelClass: SubcorpusModel
        resourcesCollectionClass: SubcorporaCollection

      syntacticCategory:
        resourcesViewClass: SyntacticCategoriesView
        resourceViewClass: SyntacticCategoryView
        resourceModelClass: SyntacticCategoryModel
        resourcesCollectionClass: SyntacticCategoriesCollection

      tag:
        resourcesViewClass: TagsView
        resourceViewClass: TagView
        resourceModelClass: TagModel
        resourcesCollectionClass: TagsCollection

      user:
        resourcesViewClass: UsersView
        resourceViewClass: UserView
        resourceModelClass: UserModel
        resourcesCollectionClass: UsersCollection

    # Show the ResourcesView subclass for `resourceName` but also make sure
    # that the "Add a new resource" subview is rendered too.
    showNewResourceView: (resourceName) ->
      if not @loggedIn() then return
      resourcePlural = @utils.pluralize resourceName
      myViewAttr = "#{resourcePlural}View"
      if @[myViewAttr] and @visibleView is @[myViewAttr]
        @visibleView.toggleNewResourceViewAnimate()
      else
        @["show#{@utils.capitalize resourcePlural}View"]
          showNewResourceView: true

    # Return camelCase `resourceName` in a bunch of other forms that are useful
    # for dynamically displaying/manipulating that resource.
    getResourceNames: (resourceName) ->
      plural = @utils.pluralize resourceName
      regular = @utils.camel2regular resourceName
      hyphen = @utils.camel2hyphen resourceName
      regular: regular
      regPlur: @utils.pluralize regular
      hyphen: hyphen
      hypPlur: @utils.pluralize hyphen
      plural: plural
      capitalized: @utils.capitalize resourceName
      capPlur: @utils.capitalize plural

    # Get `obj[attr]`, returning `default` if `attr` is not a key of `obj`.
    get: (obj, attr, default_=null) ->
      if attr of obj then obj[attr] else default_

    # Return `options` with resource-specific values (from `@myResources`) and
    # defaults.
    showResourcesViewSetDefaultOptions: (resourceName, options={}) ->
      params = @myResources[resourceName].params or {}
      _.extend options, params
      # Authentication is required to view most resources views.
      options.authenticationRequired =
        @get options, 'authenticationRequired', true
      # Most resources views do not need to be passed app settings on init.
      options.needsAppSettings = @get options, 'needsAppSettings', false
      # When using FieldDB backend, the forms view needs the active FieldDB corpus.
      options.needsActiveFieldDBCorpus =
        @get options, 'needsActiveFieldDBCorpus', false
      # Most resources views are not searchable.
      options.searchable = @get options, 'searchable', false
      # Most resources views are not elements of a corpus (only forms).
      options.corpusElement = @get options, 'corpusElement', false
      options

    # Return `options` with resource-specific values (from `@myResources`) and
    # defaults.
    showResourceViewSetDefaultOptions: (resourceName, options={}) ->
      params = @myResources[resourceName].params or {}
      _.extend options, params
      # Authentication is required to view most resources views.
      options.authenticationRequired =
        @get options, 'authenticationRequired', true
      options

    # Return `true` if the FieldDB corpus has changed.
    fieldDBCorpusHasChanged: (myViewAttr, options={}) ->
      myViewAttr is 'formsView' and
      @activeServerType() is 'FieldDB' and
      options.fieldDBCorpusHasChanged

    closeView: (view) ->
      view.close()
      @closed view

    # Instantiate a new `ResourcesView` subclass for `resourceName`.
    instantiateResourcesView: (resourceName, options={}) ->
      myParams = {}
      if options.needsAppSettings
        myParams.model = @applicationSettings
        myParams.applicationSettings = @applicationSettings
      if options.needsActiveFieldDBCorpus
        myParams.activeFieldDBCorpus = @activeFieldDBCorpus
      new @myResources[resourceName].resourcesViewClass myParams

    # Alter the visible resources view so that it displays the "create a new
    # resource" view when rendered.
    showNewResourceViewOption: (o) ->
      if o.showNewResourceView
        @visibleView.newResourceViewVisible = true
        @visibleView.weShouldFocusFirstAddViewInput = true

    # Alter a searchable resources view so that it has (or lacks) a search
    # object when rendered.
    searchableOption: (o) ->
      if o.searchable
        if o.search
          smartSearch = o.smartSearch or null
          @visibleView.setSearch o.search, smartSearch
        else
          @visibleView.deleteSearch()

    # Alter a view of resources that can be members of corpora so that the
    # resources view has (or lacks) a corpus that it should be displaying.
    corpusElementOption: (o) ->
      if o.corpusElement
        if o.corpus
          @visibleView.setCorpus o.corpus
        else
          @visibleView.deleteCorpus()


    ############################################################################
    # Show X-type resources view methods.
    # TODO: maybe these can all be dynamically defined too.
    ############################################################################

    showApplicationSettingsView: (options={}) ->
      @showResourcesView 'applicationSetting', options
    showCorporaView: (options={}) -> @showResourcesView 'corpus', options
    showFilesView: (options={}) -> @showResourcesView 'file', options
    showFormsView: (options={}) -> @showResourcesView 'form', options
    showLanguageModelsView: (options) ->
      @showResourcesView 'languageModel', options
    showMorphologicalParsersView: (options) ->
      @showResourcesView 'morphologicalParser', options
    showMorphologiesView: (options={}) ->
      @showResourcesView 'morphology', options
    showPagesView: (options={}) -> @showResourcesView 'page', options
    showPhonologiesView: (options={}) -> @showResourcesView 'phonology', options
    showSearchesView: (options) -> @showResourcesView 'search', options
    showSubcorporaView: (options={}) -> @showResourcesView 'subcorpus', options
    showUsersView: (options={}) -> @showResourcesView 'user', options


    ############################################################################
    # Show X-type "add a new" resource view methods (within the resources view)
    # TODO: maybe these can all be dynamically defined too.
    ############################################################################

    showNewFormView: -> @showNewResourceView 'form'
    showNewSubcorpusView: -> @showNewResourceView 'subcorpus'
    showNewPhonologyView: -> @showNewResourceView 'phonology'
    showNewMorphologyView: -> @showNewResourceView 'morphology'


    ############################################################################
    # Dialog-base view toggling.
    ############################################################################

    # Open/close the login dialog box
    toggleLoginDialog: -> Backbone.trigger 'loginDialog:toggle'

    openLoginDialogWithDefaults: (username, password) ->
      @loginDialog.dialogOpenWithDefaults
        username: username
        password: password

    # Open/close the register dialog box
    toggleRegisterDialog: -> Backbone.trigger 'registerDialog:toggle'

    # Open/close the alert dialog box
    toggleAlertDialog: -> Backbone.trigger 'alertDialog:toggle'

    # Open/close the tasks dialog box
    toggleTasksDialog: -> Backbone.trigger 'tasksDialog:toggle'

    # Open/close the help dialog box
    toggleHelpDialog: ->
      if not @helpDialog.hasBeenRendered
        @renderHelpDialog()
      Backbone.trigger 'helpDialog:toggle'


    ############################################################################
    # Change the jQuery UI CSS Theme
    ############################################################################

    # Change the theme if we're using the non-default one on startup.
    setTheme: ->
      activeTheme = @applicationSettings.get 'activeJQueryUITheme'
      defaultTheme = @applicationSettings.get 'defaultJQueryUITheme'
      if activeTheme isnt defaultTheme then @changeTheme()

    changeTheme: (event) ->

      # This is harder than it might at first seem.
      # Algorithm:
      # 1. get new CSS URL from selectmenu
      # 2. remove the current jQueryUI CSS <link>
      # 3. add a new jQueryUI CSS <link> with the new URL in its `href`
      # 4. ***CRUCIAL:*** when <link> `load` event fires, we ...
      # 5. get `BaseView.constructor` to refresh its `_jQueryUIColors`, which ...
      # 6. triggers a Backbone event indicating that the jQueryUI theme has changed, which ...
      # 7. causes `MainMenuView` to re-render.
      #
      # WARN: works for me on Mac with FF, Ch & Sa. Unsure of
      # cross-platform/browser support. May want to do feature detection and
      # employ a mixture of strategies 1-4.

      themeName = @applicationSettings.get 'activeJQueryUITheme'
      # TODO: this URL stuff should be in model
      newJQueryUICSSURL = "http://code.jquery.com/ui/1.11.2/themes/#{themeName}/jquery-ui.min.css"
      $jQueryUILinkElement = $('#jquery-ui-css')
      $jQueryUILinkElement.remove()
      $jQueryUILinkElement.attr href: newJQueryUICSSURL
      linkHTML = $jQueryUILinkElement.get(0).outerHTML
      $('#font-awesome-css').after linkHTML
      outerCallback = =>
        innerCallback = ->
          Backbone.trigger 'application-settings:jQueryUIThemeChanged'
        @constructor.refreshJQueryUIColors innerCallback
      @listenForLinkOnload outerCallback

      # Remaining TODOs:
      # 1. disable this feature when there is no Internet connection
      # 2. focus highlight doesn't match on login dialog (probably because it
      #    should be re-rendered after theme change)

    # Four strategies for detecting that a new CSS <link> has loaded.
    ############################################################################
    #
    # See http://www.phpied.com/when-is-a-stylesheet-really-loaded/

    # strategy #1
    listenForLinkOnload: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      if link
        link.onload = -> callback()

    # strategy #2
    addEventListenerToLink: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      eventListener = -> callback()
      if link && link.addEventListener
        link.addEventListener 'load', eventListener, false

    # strategy #3
    listenForReadyStateChange: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      if link
        link.onreadystatechange = ->
          state = link.readyState
          if state is 'loaded' or state is 'complete'
            link.onreadystatechange = null
            callback()

    # strategy #4
    checkForChangeInDocumentStyleSheets: (callback) ->
      cssnum = document.styleSheets.length
      func = ->
        if document.styleSheets.length > cssnum
          callback()
          clearInterval ti
      ti = setInterval func, 10


    ############################################################################
    # FieldDB .bug, .warn and .confirm hooks
    ############################################################################

    overrideFieldDBNotificationHooks: ->
      # Overriding FieldDB's logging hooks to do nothing
      FieldDB.FieldDBObject.verbose = -> {}
      FieldDB.FieldDBObject.debug = -> {}
      FieldDB.FieldDBObject.todo = -> {}
      FieldDB.FieldDBObject.bug = @displayBugReportDialog
      FieldDB.FieldDBObject.warn = @displayWarningMessagesDialog
      FieldDB.FieldDBObject.confirm = @displayConfirmDialog
      # FieldDB.FieldDBObject.prompt = @displayPromptDialog // TODO there is a problem with scoping 'Uncaught TypeError: this.listenTo is not a function' -GC

    displayBugReportDialog: (message, optionalLocale) =>
      deferred = FieldDB.Q.defer()
      messageChannel = "bug:#{message?.replace /[^A-Za-z]/g, ''}"
      @listenTo Backbone, messageChannel, ->
        window.open(
          "https://docs.google.com/forms/d/18KcT_SO8YxG8QNlHValEztGmFpEc4-ZrjWO76lm0mUQ/viewform")
        deferred.resolve
          message: message
          optionalLocale: optionalLocale
          response: true

      options =
        text: message
        confirm: false
        confirmEvent: messageChannel
        confirmArgument: message
      Backbone.trigger 'openAlertDialog', options

      return deferred.promise

    displayWarningMessagesDialog: (message, message2, message3, message4) ->
      console.log message, message2, message3, message4

    displayConfirmDialog: (message, optionalLocale) =>
      # TODO @jrwdunham @cesine: figure out how i18n/localization works in
      # Dative.
      deferred = FieldDB.Q.defer()
      messageChannel = "confirm:#{message?.replace /[^A-Za-z]/g, ''}"

      @listenTo Backbone, messageChannel, ->
        deferred.resolve
          message: message
          optionalLocale: optionalLocale
          response: true

      @listenTo Backbone, "cancel#{messageChannel}", ->
        deferred.reject
          message: message
          optionalLocale: optionalLocale
          response: false

      options =
        text: message
        confirm: true
        confirmEvent: messageChannel
        cancelEvent: "cancel#{messageChannel}"
        confirmArgument: message
        cancelArgument: message
      Backbone.trigger 'openAlertDialog', options

      deferred.promise

    displayPromptDialog: (message, optionalLocale) ->
      deferred = FieldDB.Q.defer()
      messageChannel = "prompt:#{message?.replace /[^A-Za-z]/g, ''}"

      @listenTo Backbone, messageChannel, (userInput) ->
        deferred.resolve
          message: message
          optionalLocale: optionalLocale
          response: userInput

      @listenTo Backbone, "cancel#{messageChannel}", ->
        deferred.reject
          message: message
          optionalLocale: optionalLocale
          response: ""

      options =
        text: message
        confirm: true
        prompt: true
        confirmEvent: messageChannel
        cancelEvent: 'cancel' + messageChannel
        confirmArgument: message
        cancelArgument: message
      Backbone.trigger 'openAlertDialog', options

      deferred.promise

    displayConfirmIdentityDialog: (message, successCallback, failureCallback,
    cancelCallback) =>
      cancelCallback = cancelCallback or failureCallback
      if @applicationSettings.get 'fieldDBApplication' isnt
      FieldDB.FieldDBObject.application
        @applicationSettings.set 'fieldDBApplication',
          FieldDB.FieldDBObject.application
      @displayPromptDialog(message).then(
        (dialog) =>
          @applicationSettings
            .get('fieldDBApplication')
            .authentication
            .confirmIdentity(password: dialog.response)
            .then successCallback, failureCallback
      ,
        cancelCallback
      )

    # Change `attribute` to `value` in
    # `applicationSettings.get('<resource_name_plural>DisplaySettings').`
    changeDisplaySetting: (resource, attribute, value) ->
      try
        displaySettings = @applicationSettings.get "#{resource}DisplaySettings"
        displaySettings[attribute] = value
        @applicationSettings.save "#{resource}DisplaySettings", displaySettings


    ############################################################################
    # Resource Displayer Dialog logic
    ############################################################################
    #
    # These are the jQuery Dialog Boxes that are used to display a single
    # resource view.

    maxNoResourceDisplayerDialogs: 4

    getResourceDisplayerDialogs: ->
      for int in [1..@maxNoResourceDisplayerDialogs]
        @["resourceDisplayerDialog#{int}"] =
          new ResourceDisplayerDialogView index: int

    renderResourceDisplayerDialogs: ->
      for int in [1..@maxNoResourceDisplayerDialogs]
        @["resourceDisplayerDialog#{int}"]
          .setElement(@$("#resource-displayer-dialog-container-#{int}"))
          .render()
        @rendered @["resourceDisplayerDialog#{int}"]

    # Render the passed in resource view in the application-wide
    # `@resourceDisplayerDialog`
    showResourceInDialog: (resourceView) ->
      if @resourceViewAlreadyDisplayed resourceView
        Backbone.trigger 'resourceAlreadyDisplayedInDialog', resourceView
      else
        if not resourceView.model.collection
          collectionClass =
            @myResources[resourceView.resourceName].resourcesCollectionClass
          try
            resourceView.model.collection = new collectionClass()
        oldestResourceDisplayer = @getOldestResourceDisplayerDialog()
        oldestResourceDisplayer.showResourceView resourceView

    resourceViewAlreadyDisplayed: (resourceView) ->
      @resourceAlreadyDisplayed resourceView.model

    resourceAlreadyDisplayed: (resourceModel) ->
      isit = false
      for int in [1..@maxNoResourceDisplayerDialogs]
        try
          displayedModel = @["resourceDisplayerDialog#{int}"].resourceView.model
          if displayedModel.get('id') is resourceModel.get('id') and
          displayedModel.constructor.name is resourceModel.constructor.name
            isit = true
      isit

    getResourceViewClassFromResourceName: (resourceName) ->
      @myResources[resourceName].resourceViewClass

    # Create a view for the passed in `resourceModel` and render it in the
    # application-wide `@resourceDisplayerDialog`.
    showResourceModelInDialog: (resourceModel, resourceName) ->
      resourceViewClass = @getResourceViewClassFromResourceName resourceName
      resourceView = new resourceViewClass(model: resourceModel)
      if @resourceAlreadyDisplayed resourceModel
        Backbone.trigger 'resourceAlreadyDisplayedInDialog', resourceView
      else
        @showResourceInDialog resourceView

    getOldestResourceDisplayerDialog: ->
      oldest = @resourceDisplayerDialog1
      for int in [2..@maxNoResourceDisplayerDialogs]
        other = @["resourceDisplayerDialog#{int}"]
        if other.timestamp < oldest.timestamp then oldest = other
      oldest

    openExporterDialog: (options) ->
      @exporterDialog.setToBeExported options
      #@exporterDialog.generateExport()
      @exporterDialog.dialogOpen()

