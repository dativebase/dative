define [
  './base'
  './csv-import-row'
  './csv-import-header'
  './exporter-collection-csv'
  './../models/form'
  './../models/file'
  './../models/tag'
  './../models/elicitation-method'
  './../models/user-old'
  './../models/source'
  './../models/speaker'
  './../models/syntactic-category'
  './../collections/forms'
  './../collections/tags'
  './../utils/globals'
  './../templates/csv-import'
], (BaseView, CSVImportRowView, CSVImportHeaderView, ExporterCollectionCSVView,
  FormModel, FileModel, TagModel, ElicitationMethodModel, UserModel,
  SourceModel, SpeakerModel, SyntacticCategoryModel, FormsCollection,
  TagsCollection, globals, importerTemplate) ->

  # Importer View
  # -------------
  #
  # This is the importer view. At present it only allows for *CSV* import of
  # collections of *forms*.
  #
  # It tries to guess the underlying values of relational values represented as
  # strings. That is, it will try to identify an existing user that corresponds
  # to an elicitor string like 'Joel Dunham'.
  #
  # **Note:** the import progresses row-by-row, in sequence. This view does not
  # make (potentially) hundreds of simultaneous create/POST requests. It may be
  # desirable to implement a compromise where batches of n (= 10 ?) rows are
  # imported simultaneously.
  #
  # Other features:
  #
  # - spreadsheet-like (i.e., tabular) preview of to-be-imported forms
  # - validation (based on FormModel.validate)
  # - warnings of "un-parse-able" string data (e.g., source strings that cannot
  #   be parsed to source objects)
  # - selective import: user can manually select a subset of forms to import.

  # TODO:
  #
  # - interface for fixing all fixable warnings, i.e., create tag for '...'
  #
  # - offer to close the file after import has completed. It holds a lot of
  #   memory.
  #
  # - Create button that hides (destroys?) all already-imported rows.
  #
  # - Allow users to Shift-click ranges of rows to select them. (Maybe?)
  #
  # - If there are id values in the CSV import file, we may want to ask the
  #   user if they want to UPDATE the relevant forms, as opposed to creating
  #   them.
  #
  # - configurable date validation: let user choose among formats for date
  #   elicited
  #
  # - PERFORMANCE!:
  #
  #   - Consider only rendering the row views for the rows that are visible in
  #     the overflow container. If the import file is large, then rendering
  #     thousands of views will stall the browser. The disadvantage to this
  #     approach is that we will need to listen for scroll events and render row
  #     views in response. Similarly, the "Preview Selected" button should only
  #     request preview dispays from the rows visible within the scrollable
  #     container and request additional previews as rows become visible upon
  #     scroll events. See http://stackoverflow.com/questions/487073/check-if-element-is-visible-after-scrolling
  #
  #   - Searching for duplicates in bulk will break the OLD's search mechanism
  #     if you have too many (i.e., thousands) of dis/conjuncts. We therefore
  #     need to perform this search in batches.
  #
  # - Help dialog is not scrolling to "Importing Forms". Is this a general issue?
  #
  # - allow users to use the import interface as an input interface; i.e., allow
  #   them to create a new row and enter text to input data.
  #
  # - the row view and the preview's FormView view should be doubly binded to
  #   the model: when you change the row, it should change the formview and
  #   vice versa.


  class CSVImportView extends BaseView

    template: importerTemplate

    initialize: ->

      # Set vars to hold validation data.
      @defaultValidationState()

      @hideImportReportContainer()

      # This collection is passed to our row view instances so that they can
      # give it to their form model instances for create (POST) requests.
      @formsCollection = new FormsCollection()

      # Will hold the array that is built from the CSV file to be imported.
      @importCSVArray = null

      # Will hold the file object given to us by the file API.
      @fileBLOB = null

      # List of unique filenames strings that we may need to search for. This
      # is necessary if any of our rows contains values in the "files" column.
      # We centralize the file search in this parent class (as opposed to
      # having each row view perform its own request against file resources.)
      @filenames = []

      # Maps filename strings to file objects. This is populated after a
      # successful search over file resources.
      @filenames2objects = {}

      # Array of `CSVImportRowView` instances that control the display and
      # logic of CSV rows to be imported.
      @rowViews = []

      # A `CSVImportHeaderView` instance. This holds the <select>s for labeling
      # the CSV columns with form attribute names.
      @headerView = null

      # An array of column labels for each column in the CSV file.
      @columnLabels = []

      # For performing searches over file resources.
      @dummyFileModel = new FileModel()

      # This is used to get the possible values for a form's relational fields,
      # e.g., the array of users for enterer values.
      @dummyFormModel = new FormModel()

      # If this is `true`, then success on a request to
      # `@dummyFormModel.getNewResourceData()` will result in
      # `validateSelected` being called.
      @validateAfterGettingNewFormData = false

      # If this is `true`, then validating all selected rows will, when done,
      # call `@searchForDuplicates`, which, in turn, will call
      # `@importSelected`
      @importPostValidation = false

      @listenToEvents()

      # Since we will be importing forms, we need the data from the server that
      # tells us what the relational values of forms can be, i.e., possible
      # speakers, users, etc. Assuming the call to `getNewResourceData` is
      # successful, the `globals` `Backbone.Model` instance will have
      # attributes for `speakers`, etc.
      @dummyFormModel.getNewResourceData()

      # We haven't asked any of our row views to render/display their
      # `FormView` previews yet.
      @previewsVisible = false

      # An array of form objects representing possible duplicates of the forms
      # we are about to import.
      @duplicatesFound = []

      # Holds a TagModel instance; each import request creates one of these so
      # that all forms imported can be tagged with it.
      @importTag = null

      # Clicking the "Stop Importing" button sets this to `true` and the
      # current import will halt when no request is pending.
      @stopCurrentImportAtNextOpportunity = false

      # Setting this to true will cause the importer to silently import
      # possible duplicates without alerting the user.
      @importAllDespiteDuplicatesState = false

      # Setting this to true will cause the importer to silently skip over
      # possible duplicates without alerting the user.
      @skipAllDuplicatesState = false

      @defaultImportOptionsState()

    # Set validation-related variables to defaults.
    defaultValidationState: ->
      @warnings = []
      @rowWarnings = {}
      @errors = []
      @rowErrors = {}
      @solutions = {}

    # Vars for how we handle imports.
    defaultImportOptionsState: ->
      @parseTranslations = true
      @translationDelimiter = ';'
      @identifyTranslationCompatibilities = true

    listenToEvents: ->
      super

      # React to the form model trying to get its relational data.
      @listenTo @dummyFormModel, 'getNewFormDataSuccess',
        @getStringToObjectMappers
      @listenTo @dummyFormModel, 'getNewFormDataFail',
        @getNewFormDataFail

      # React to the form model searching for duplicates.
      @listenTo @dummyFormModel, 'searchSuccess', @searchForDuplicatesSuccess
      @listenTo @dummyFormModel, 'searchFail', @searchForDuplicatesFail

      # React to the file model trying to perform a search.
      @listenTo @dummyFileModel, 'searchSuccess', @fileSearchSuccess
      @listenTo @dummyFileModel, 'searchFail', @fileSearchFail

      # The alert/confirm dialog may trigger this, if the user really wants to
      # show a lot of previews.
      @listenTo Backbone, 'showPreviews', @showPreviews

      @listenToRowViews()
      @listenToHeaderView()

      # If a search for duplicates fails and the user clicks "Ok" on the
      # confirm dialog that pops up, then we proceed with importing all of the
      # selected rows.
      @listenTo @, 'importSelected', @importSelected

      # There are several exit points during an import where the import can be
      # canceled. The confirm dialog will trigger this event in those cases.
      # Cases:
      # - search for duplicates has failed.
      # - import tag creation has failed.
      @listenTo @, 'cancelImportSelected', @cancelImportSelected

      # If the user has clicked "Import Selected" and decides to continue the
      # import despite the fact that there are errors and/or warnings, then
      # 'searchForDuplicates' will be triggered by the confirm dialog.
      @listenTo @, 'searchForDuplicates', @searchForDuplicates

      # If we have found duplicates for a row and the user wants to
      # import anyway, this event will be triggered by the confirm dialog.
      @listenTo @, 'importDespiteDuplicates', @importDespiteDuplicates

      @listenTo @, 'dontImportBecauseDuplicates', @dontImportBecauseDuplicates

      # If we have failed to create an "import tag" and the user wants to
      # import anyway, this event will be triggered by the confirm dialog.
      @listenTo @, 'importDespiteNoImportTag', @importDespiteNoImportTag

      # This is called by the duplicates alert dialog when the user clicks
      # "Skip All Duplicates". It causes the importer to stop alerting the user
      # to possible duplicates and just silently skips them.
      @listenTo @, 'skipAllDuplicates', @skipAllDuplicates

      # This is called by the duplicates alert dialog when the user clicks
      # "Import All Anyway". It causes the importer to stop alerting the user
      # to possible duplicates and just imports everything.
      @listenTo @, 'importAllDespiteDuplicates', @importAllDespiteDuplicates

      # This is triggered by the alert dialog when the user clicks the "Stop
      # Import" button there. We call the private method here because there
      # will be no request whose termination we must wait for; we can just
      # cancel the import and report the summary right away.
      @listenTo @, 'stopCurrentImportSelected', @__stopCurrentImportSelected

    listenToRowViews: ->
      for view in @rowViews
        @listenTo view, 'focusCell', @focusCell
        @listenTo view, 'rowSelected', @allSelectedButtonsState
        @listenTo view, 'rowDeselected', @allSelectedButtonsState

    # A row view has told us it wants cell `coords[1]` of row `coords[0]` to be
    # focused.
    focusCell: (coords) ->
      try
        @rowViews[coords[0]].focusCell coords[1]

    listenToHeaderView: ->
      if @headerView
        @listenTo @headerView, 'columnWidthsChanged', @setColumnWidths
        @listenTo @headerView, 'columnLabelsChanged', @columnLabelsChanged

    events:
      'click .choose-import-file-button':         'clickFileUploadInput'
      'change [name=file-upload-input]':          'handleFileSelect'
      'click button.select-all-for-import':       'selectAllFormsForImport'
      'click button.select-none-for-import':      'deselectAllFormsForImport'
      'click button.import-selected-button':      'importSelectedPreflight'
      'click button.stop-import-selected-button': 'stopCurrentImportSelected'
      'click button.preview-selected-button':     'togglePreviews'
      'click button.validate-selected-button':    'validateSelected'
      'click button.hide-import-widget':          'hideMe'
      'click button.discard-file-button':         'discardFile'
      'click button.import-solution':             'performImportSolution'
      'click button.toggle-errors':               'toggleErrors'
      'click button.toggle-warnings':             'toggleWarnings'
      'click button.fix-all-warnings':            'fixAllWarnings'
      'click button.import-help':                 'openImportHelp'
      'click button.import-options-button':       'toggleOptions'
      'click i.parse-translations':               'toggleParseTranslations'
      'click i.identify-translation-compatibilities':
        'toggleIdentifyTranslationCompatibilities'
      'input input[name=translation_delimiter]':  'setTranslationDelimiter'

    # User has clicked "Fix all warnings" button. We find all warnings with
    # solutions and put them in a queue. Then we help the user to fix them one
    # by one.
    fixAllWarnings: ->
      @solutionsQueue = []
      for msg, warningObject of @rowWarnings
        if warningObject.solution
          solution = @solutions[warningObject.solution.id]
          if solution
            @solutionsQueue.push solution
      @performNextSolution()

    # Perform the first solution in the `@solutionsQueue`.
    performNextSolution: ->
      solution = @solutionsQueue.shift()
      if solution
        if solution.resource of @creatableResources
          meta = @creatableResources[solution.resource]
          resourceModelClass = meta.modelClass
          coreAttribute = meta.coreAttribute
          resourceModel = new resourceModelClass
          resourceModel.set coreAttribute, solution.val
          # The resource creation may succeed, fail, or the user may abort it.
          # In any of these cases, we move on to performing the next solution.
          @listenToOnce resourceModel,
            "add#{@utils.capitalize solution.resource}Success",
            @performNextSolution
          @listenToOnce resourceModel,
            "add#{@utils.capitalize solution.resource}Fail",
            @performNextSolution
          @listenToOnce resourceModel,
            'resourceDisplayerDialogHoldingModelClosed', @performNextSolution
          Backbone.trigger 'showResourceModelInDialog', resourceModel,
            solution.resource
        else
          console.log "Sorry, we are unable to create a #{solution.resource}"
          @performNextSolution()
      else
        @allSolutionsPerformed()

    # We have created all of the resources needed for this import (or, at
    # least, we have given the user the opportunity to create them), so we
    # re-run validation indirectly by first updating our related resources.
    # TODO: alert and summarize what was accomplished
    # TODO: hide "Fix all warnings" button if there are no warnings with solutions.
    allSolutionsPerformed: ->
      @validateAfterGettingNewFormData = true
      @dummyFormModel.getNewResourceData()

    # Update all row views with the current import options values.
    updateRowViewsWithImportOptions: ->
      for view in @rowViews
        view.parseTranslations = @parseTranslations
        view.identifyTranslationCompatibilities = @identifyTranslationCompatibilities
        view.translationDelimiter = @translationDelimiter

    setTranslationDelimiter: ->
      newDelimiter = @$('input[name=translation_delimiter]').first().val()
      if newDelimiter
        @translationDelimiter = newDelimiter
      else
        @translationDelimiter = ';'
      @updateRowViewsWithImportOptions()

    toggleParseTranslations: ->
      $checkBox = @$ 'i.parse-translations'
      if $checkBox.hasClass 'fa-check-square'
        $checkBox.removeClass 'fa-check-square'
        $checkBox.addClass 'fa-square'
        @parseTranslations = false
      else
        $checkBox.removeClass 'fa-square'
        $checkBox.addClass 'fa-check-square'
        @parseTranslations = true
      @updateRowViewsWithImportOptions()

    toggleIdentifyTranslationCompatibilities: ->
      $checkBox = @$ 'i.identify-translation-compatibilities'
      if $checkBox.hasClass 'fa-check-square'
        $checkBox.removeClass 'fa-check-square'
        $checkBox.addClass 'fa-square'
        @identifyTranslationCompatibilities = false
      else
        $checkBox.removeClass 'fa-square'
        $checkBox.addClass 'fa-check-square'
        @identifyTranslationCompatibilities = true
      @updateRowViewsWithImportOptions()

    # Toggle the visibility of the options <div>.
    toggleOptions: ->
      $optionsContainer = @$ '.import-options-container'
      if $optionsContainer.is ':visible'
        $optionsContainer.slideUp()
      else
        $optionsContainer.slideDown()

    # Tell the Help dialog to open itself and search for "importing forms"
    # and scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want.
    openImportHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: 'importing forms'
        scrollToIndex: 0
      )

    toggleErrors: ->
      $container = @$ 'div.general-errors-list-wrapper'
      if $container.is ':visible'
        $container.slideUp()
        @$('button.toggle-errors i')
          .removeClass 'fa-caret-down'
          .addClass 'fa-caret-right'
      else
        $container.slideDown()
        @$('button.toggle-errors i')
          .removeClass 'fa-caret-right'
          .addClass 'fa-caret-down'

    toggleWarnings: ->
      $container = @$ 'div.general-warnings-list-wrapper'
      if $container.is ':visible'
        $container.slideUp()
        @$('button.toggle-warnings i')
          .removeClass 'fa-caret-down'
          .addClass 'fa-caret-right'
      else
        $container.slideDown()
        @$('button.toggle-warnings i')
          .removeClass 'fa-caret-right'
          .addClass 'fa-caret-down'

    # Map the names of resources that we can create to metadata about them.
    creatableResources:
      tag:
        modelClass: TagModel
        coreAttribute: 'name'
      elicitationMethod:
        modelClass: ElicitationMethodModel
        coreAttribute: 'name'
      user:
        modelClass: UserModel
        coreAttribute: 'first_name'
      source:
        modelClass: SourceModel
        coreAttribute: 'author'
      speaker:
        modelClass: SpeakerModel
        coreAttribute: 'first_name'
      syntacticCategory:
        modelClass: SyntacticCategoryModel
        coreAttribute: 'name'
      file:
        modelClass: FileModel
        coreAttribute: 'name'

    # This method is called when a Warning/Error's "solution" button is
    # clicked. We try to "perform the solution", which, at this point, can only
    # mean creating a new resource model and asking the app view to display it
    # in a dialog box so that the user can create it.
    performImportSolution: (event) ->
      solutionId = @$(event.currentTarget).attr('data-solution-id')
      if solutionId
        solution = @solutions[solutionId]
        if solution
          if solution.resource of @creatableResources
            meta = @creatableResources[solution.resource]
            resourceModelClass = meta.modelClass
            coreAttribute = meta.coreAttribute
            resourceModel = new resourceModelClass
            resourceModel.set coreAttribute, solution.val
            @listenToOnce resourceModel,
              "add#{@utils.capitalize solution.resource}Success",
              @resourceCreated
            Backbone.trigger 'showResourceModelInDialog', resourceModel,
              solution.resource
          else
            console.log "Sorry, we are unable to create a #{solution.resource}"
        else
          console.log "Sorry, we cannot find a solution for this warning/error"
      else
        console.log 'Sorry, there is no action tied to this button'

    # We have created a resource so we re-run validation indirectly by first
    # updating our related resources.
    resourceCreated: (resourceModel) ->
      @validateAfterGettingNewFormData = true
      @dummyFormModel.getNewResourceData()

    # User has clicked on the "X" button next to the "Choose File" button,
    # indicating that they no longer want to import from this file.
    discardFile: ->
      @spin 'discarding CSV file'
      x = =>
        @clearFileMetadata()
        @$('.import-preview-table-head').html ''
        @$('.import-preview-table-body').html ''
        @fileBLOB = null
        @importCSVArray = null
        @closeRowViews()
        @$('.dative-importer-preview').slideUp()
        @$('button.discard-file-button').hide()
        @stopSpin()
      setTimeout x, 5

    # Close all of our row views.
    closeRowViews: ->
      while @rowViews.length
        rowView = @rowViews.pop()
        rowView.close()
        @stopListening rowView
        @closed rowView

    hideMe: -> @trigger 'hideMe'

    hideGeneralWarningsAndErrors: ->
      @$('.general-errors-container').hide()
      @$('.general-warnings-container').hide()

    # Create an object attribute that keys to objects which in turn map string
    # representations of relational values to the corresponding object
    # representations. E.g., objects that map things like 'Joel Dunham' to
    # `{first_name: 'Joel', ...}`, etc. These objects are used to "parse" user
    # input values for "elicitor", etc. in CSV import files.
    getStringToObjectMappers: (data) ->
      @storeOptionsDataGlobally data
      @stringToObjectMappers = {}
      for attr, meta of @relationalAttributesMeta
        mapper = []
        options = globals.get(meta.optionsAttribute).data
        for optionObject in options
          # We use the CSV exporter's `toString`-type methods to generate the
          # string reps of all available objects.
          stringRep =
            ExporterCollectionCSVView::[meta.toStringConverter] optionObject
          mapper.push [stringRep, optionObject]
        @stringToObjectMappers[attr] = mapper
      if @validateAfterGettingNewFormData
        @validateAfterGettingNewFormData = false
        for rowView in @rowViews
          rowView.stringToObjectMappers = @stringToObjectMappers
        @validateSelected()

    getNewFormDataFail: ->
      @validateAfterGettingNewFormData = false

    # This object maps the names of relational form attributes to metadata
    # about them; specifically, to their options attribute in `globals` and to
    # the method used by the CSV exporter view to convert their values to
    # strings.
    relationalAttributesMeta:
      elicitation_method:
        optionsAttribute: 'elicitation_methods'
        toStringConverter: 'objectWithNameToString'
      elicitor:
        optionsAttribute: 'users'
        toStringConverter: 'personToString'
      source:
        optionsAttribute: 'sources'
        toStringConverter: 'sourceToString'
      speaker:
        optionsAttribute: 'speakers'
        toStringConverter: 'personToString'
      syntactic_category:
        optionsAttribute: 'syntactic_categories'
        toStringConverter: 'objectWithNameToString'
      verifier:
        optionsAttribute: 'users'
        toStringConverter: 'personToString'

    importSelectedVarsDefaultState: ->
      @importsSucceeded = 0
      @importsFailed = 0
      @importsAbortedBecauseDuplicates = 0
      @importTag = null

    # This method is called when the "Import Selected" button is clicked.
    # It ultimately imports all of the CSV rows that are selected.
    importSelectedPreflight: ->
      @resetImportReportContainer()
      @showImportReportContainer()
      @disableAllControls()
      @importSelectedVarsDefaultState()
      selectedRows = (r for r in @rowViews when r.selected)
      if selectedRows.length > 0
        @importPostValidation = true
        @validateSelected()
      else
        @enableAllControls()
        # It should not be possible to get here: the UI should disable the
        # import button when none are selected.
        console.log 'there are no selected rows to import!'

    # We have validated all of the rows and we have performed a duplicates
    # search. Now we create a special tag just for this import, a tag that will
    # be assigned to each form that we create in this multi-import. This will
    # make it easier for users to track how data have been created in the
    # system.
    importSelected: ->
      # Here we ask the master `AppView` instance to prevent the user from
      # navigating away during an in-progress import.
      msg = 'You are in the middle of importing a number of CSV rows and cannot
        navigate to a different page until the import ends or you stop it
        manually.'
      Backbone.trigger 'setPreventNavigation', msg
      @spin 'Importing selected and valid rows'
      @createImportTag()

    # Create a special tag just for this import. Its name is "_import " followed
    # by the current Unix timestamp. It als
    createImportTag: ->
      now = new Date()
      humanNow = @utils.humanDatetime now
      importer = globals.applicationSettings.get 'loggedInUser'
      tag = new TagModel(
        {
          name: "_import #{now.getTime()}"
          description: "This tag was given automatically to all forms that were
            imported by #{importer.first_name} #{importer.last_name} on
            #{humanNow}, using the CSV file “#{@fileBLOB.name}”."
        },
        {collection: new TagsCollection()}
      )
      @listenToOnce tag, 'addTagSuccess', @importTagCreateSuccess
      @listenToOnce tag, 'addTagFail', @importTagCreateFail
      tag.collection.addResource tag

    # We have succeeded in creating an import tag. We set it to `@importTag`
    # and will use it to tag all of the forms that we import in this batch.
    importTagCreateSuccess: (tagModel) ->
      # Triggering this event is necessary for the new tag to be registered by
      # `globals`.
      Backbone.trigger "addTagSuccess", tagModel
      @importTag = tagModel
      @importSelectedContinue()

    # We failed to create an import tag (for some reason). Right now we are
    # just going to proceed with the import without it.
    importTagCreateFail: ->
      @importTag = null
      @alertUserOfImportTagCreateFail()

    # We have, for some reason, failed to create an import tag. Display a
    # confirm dialog which lets the user abort the import because of this
    # failure to create the import tag.
    alertUserOfImportTagCreateFail: ->
      options =
        text: "An error occurred when trying to create a special tag for the
          forms that you are trying to import. Click “Ok” to proceed with
          the import anyway, i.e., without an “import tag”. Click
          “Cancel” to cancel the import."
        confirm: true
        confirmEvent: 'importDespiteNoImportTag'
        cancelEvent: 'cancelImportSelected'
        eventTarget: @
      Backbone.trigger 'openAlertDialog', options

    # The user has chosen to continue with the import, despite the fact that we
    # were not able to create an import tag.
    importDespiteNoImportTag: -> @importSelectedContinue()

    # Now, really, we begin importing all of the valid and selected rows in
    # sequence. This is called after the attempt to create the import tag.
    importSelectedContinue: ->
      @showStopButton()
      @rowToImportIndex = 0
      @importRow()

    importRow: ->
      Backbone.trigger 'closeAllResourceDisplayerDialogs'
      # Cancel/stop the import if the user has clicked the "Stop Importing"
      # button recently".
      if @stopCurrentImportAtNextOpportunity
        @stopCurrentImportAtNextOpportunity = false
        @__stopCurrentImportSelected()
        return
      rowToImport = @rowViews[@rowToImportIndex]
      # `undefined` means there is now rowView at the current index and
      # therefore we are done with the import selected task.
      if rowToImport is undefined
        @importSelectedDone()
      else
        if rowToImport.selected and rowToImport.valid
          if @importAllDespiteDuplicatesState
            @importRowForReal()
          else
            duplicates = @getDuplicatesForRow rowToImport
            if duplicates.length > 0
              if @skipAllDuplicatesState
                @dontImportBecauseDuplicates()
              else
                @alertUserOfDuplicatesForRow rowToImport, duplicates
            else
              @importRowForReal()
        # This row cannot be imported, so we increment the index and recur.
        else
          @importNextRow()

    # Open a confirm dialog that notifies the user that potential duplicates
    # have been found for the row at `@rowToImportIndex`. The button that the
    # user clicks determines whether to proceed with the import of the row in
    # question, or whether to move on to the next row.
    alertUserOfDuplicatesForRow: (row, duplicates) ->
      row.displayDuplicatesInDialogBoxes duplicates
      duplicatesCount = duplicates.length
      options =
        text: "We found #{duplicatesCount} possible
          #{@utils.pluralizeByNum 'duplicate', duplicatesCount} for the form in
          row #{row.rowIndex + 1}. See the dialog box(es). Click “Import
          Anyway” to import this row despite possible duplication. Click
          “Skip Duplicate” to avoid importing this row and move on to the
          next one. Click “Import All Anyway” to import this and all
          subsequent possible duplicates. Click “Skip All Duplicates” to
          avoid importing this and any subsequent duplicate rows. Click “Stop
          Importing” to abort the import."

        confirm: true

        confirmEvent: 'importDespiteDuplicates'
        confirmButtonText: 'Import Anyway'

        confirmAllEvent: 'importAllDespiteDuplicates'
        confirmAllButtonText: 'Import All Anyway'

        cancelEvent: 'dontImportBecauseDuplicates'
        cancelButtonText: 'Skip Duplicate'

        cancelAllEvent: 'skipAllDuplicates'
        cancelAllButtonText: 'Skip All Duplicates'

        specialButtonEvent: 'stopCurrentImportSelected'
        specialButtonText: 'Stop Importing'

        eventTarget: @
      Backbone.trigger 'openAlertDialog', options

    # Move on to trying to import the next row; the current row has possible
    # duplicates already on the server and the user has elected not to import
    # it.
    dontImportBecauseDuplicates: ->
      @importsAbortedBecauseDuplicates += 1
      @updateImportReportContainer()
      @rowViews[@rowToImportIndex].setImportStateCanceledBecauseDuplicates()
      @importNextRow()

    # Move on to trying to import the next row; the current row has possible
    # duplicates already on the server and the user has elected not to import
    # it.
    skipAllDuplicates: ->
      @skipAllDuplicatesState = true
      @dontImportBecauseDuplicates()

    # Import the next row.
    importNextRow: ->
      @rowToImportIndex += 1
      @importRow()

    # Import the current row, despite the fact that we have found possible
    # duplicates of it already on the server.
    importDespiteDuplicates: -> @importRowForReal()

    # Import the current row and all subsequent possible duplicates.
    importAllDespiteDuplicates: ->
      @importAllDespiteDuplicatesState = true
      @importRowForReal()

    # We know that the row at `@rowToImportIndex` is selected and valid and the
    # user has given us the go-ahead to import despite any duplicates that may
    # exist. Therefore, we tell the row to import/create itself and we wait to
    # hear that that request has terminated, whereupon we initiate import of
    # the next row.
    importRowForReal: ->
      Backbone.trigger 'closeAllResourceDisplayerDialogs'
      rowToImport = @rowViews[@rowToImportIndex]
      @rowToImportIndex += 1
      @listenToOnce rowToImport, 'importAttemptTerminated',
        @importAttemptTerminated
      if @importTag
        # TODO/WARNING: this can trigger an error because somehow/sometimes
        # (how?) the tags attribute of a form model can be something other than
        # an array. How can this possibly happen? It shouldn't be able to
        # happen.
        try
          rowToImport.model.get('tags').push(
            id: @importTag.get('id')
            name: @importTag.get('name')
          )
        catch
          tags = [
            id: @importTag.get('id')
            name: @importTag.get('name')
          ]
          rowToImport.model.set 'tags', tags
      # @scrollToRow rowToImport
      rowToImport.silentAddFormSuccess = true
      rowToImport.issueCreateRequest()

    # Scrolling to the row that is currently being imported is nice because it
    # keeps it in view, however, it makes it very difficult to access the "Stop
    # Importing", so I'm not using this until it can be improved.
    scrollToRow: (rowToImport) ->
      rowToImport.$('button.import-csv-row').first().focus()

    # A CSV row view is telling us that an import/create request to the server
    # has terminated. `success` is a boolean that indicates if the attempt was
    # successful (`true`) or a failure (`false`).
    importAttemptTerminated: (success) ->
      if success
        @importsSucceeded += 1
      else
        @importsFailed += 1
      @updateImportReportContainer()
      @importRow()

    updateImportReportContainer: ->
      @$('.import-success-count-count')
        .text "#{@utils.integerWithCommas @importsSucceeded} successful imports"
      @$('.import-fail-count-count')
        .text "#{@utils.integerWithCommas @importsFailed} failed imports"
      @$('.import-abort-count-count')
        .text "#{@utils.integerWithCommas @importsAbortedBecauseDuplicates}
          aborted imports"

    resetImportReportContainer: ->
      @$('.import-success-count-count').text '0 successful imports'
      @$('.import-fail-count-count').text '0 failed imports'
      @$('.import-abort-count-count').text '0 aborted imports'

    hideImportReportContainer: ->
      @$('.import-report-container').hide()

    showImportReportContainer: ->
      @$('.import-report-container').show()

    # Return the duplicates that correspond to `row`.
    getDuplicatesForRow: (row) ->
      if @duplicatesFound.length > 0
        matcher = {
          transcription: row.model.get('transcription').normalize('NFD')
          phonetic_transcription:
            row.model.get('phonetic_transcription').normalize('NFD')
          narrow_phonetic_transcription:
            row.model.get('narrow_phonetic_transcription').normalize('NFD')
          transcription: row.model.get('transcription').normalize('NFD')
          morpheme_break: row.model.get('morpheme_break').normalize('NFD')
          morpheme_gloss: row.model.get('morpheme_gloss').normalize('NFD')
          grammaticality: row.model.get('grammaticality').normalize('NFD')
        }
        tmp = _.where @duplicatesFound, matcher
        duplicates = []
        translations = row.model.get 'translations'
        for potDup in tmp
          transTranscrsThere = true
          transGramsThere = true
          potDupTransTranscrs = (t.transcription for t in potDup.translations)
          potDupTransGrams = (t.grammaticality for t in potDup.translations)
          for translation in translations
            if (translation.transcription.normalize('NFD') not in
            potDupTransTranscrs)
              transTranscrsThere = false
            if (translation.grammaticality.normalize('NFD') not in
            potDupTransGrams)
              transGramsThere = false
          if transTranscrsThere and transGramsThere
            duplicates.push potDup
        duplicates
      else
        []

    # User has clicked the "Stop Importing" button. Since requests may be in
    # progress, we make a note to stop the import at the next chance we get.
    stopCurrentImportSelected: ->
      @stopCurrentImportAtNextOpportunity = true

    # Private method for actually stopping the import. Logic elsewhere calls
    # this when no requests are pending.
    __stopCurrentImportSelected: ->
      Backbone.trigger 'closeAllResourceDisplayerDialogs'
      @importSelectedDone true

    # This is called when the "Import Selected" task has completed because
    # there are no more rows to import.
    # If `midwayAbort` is true, it means that the user has aborted/canceled the
    # import without waiting for it to complete.
    importSelectedDone: (midwayAbort=false) ->
      @stopSpin()
      @enableAllControls()
      @hideStopButton()
      @updateImportReportContainer()
      @alertImportSummary midwayAbort
      @resetImportDefaults()
      # Triggering the following event will cause the `FormsBrowseView`
      # instance to navigate to the last page and update its pagination info
      # according to the current state of the database.
      Backbone.trigger 'browseAllFormsAfterImport'
      Backbone.trigger 'unsetPreventNavigation'

    resetImportDefaults: ->
      @stopCurrentImportAtNextOpportunity = false
      @importAllDespiteDuplicatesState = false
      @skipAllDuplicatesState = false

    hideStopButton: -> @$('.stop-import-selected-button').hide()

    showStopButton: -> @$('.stop-import-selected-button').show()

    # Alert the user that we've finished attempting to import all of the
    # selected rows. Summarize what has been accomplished. Note that the
    # complicated-looking logic here is just for creating a nice human-readable
    # report based on counts of successes, failures and
    # aborts-due-to-duplicates.
    alertImportSummary: (midwayAbort=false) ->
      switch @importsSucceeded
        when 1 then verbSuccess = 'was'
        else verbSuccess = 'were'
      switch @importsAbortedBecauseDuplicates
        when 1 then verbAbort = 'was'
        else verbAbort = 'were'
      importAttempts = @importsSucceeded + @importsFailed +
        @importsAbortedBecauseDuplicates
      alertMsg = "You have attempted to import
        #{@utils.number2word importAttempts}
        #{@utils.pluralizeByNum 'form', importAttempts}."
      if midwayAbort
        alertMsg = "You have CANCELED the import mid-process. #{alertMsg}"
      if @importsSucceeded > 0
        alertMsg = "#{alertMsg}
          #{@utils.capitalize @utils.number2word(@importsSucceeded)} import
          #{@utils.pluralizeByNum 'attempt', @importsSucceeded} #{verbSuccess}
          successful."
      else
        alertMsg = "#{alertMsg} No import attempts were successful."
      if @importsFailed > 0
        alertMsg = "#{alertMsg}
          #{@utils.capitalize @utils.number2word(@importsFailed)} import
          #{@utils.pluralizeByNum 'attempt', @importsFailed} failed."
      if @importsAbortedBecauseDuplicates > 0
        alertMsg = "#{alertMsg}
          #{@utils.capitalize @utils.number2word(@importsAbortedBecauseDuplicates)}
          import
          #{@utils.pluralizeByNum 'attempt', @importsAbortedBecauseDuplicates}
          #{verbAbort} aborted because probable duplicates were found."
      if @importTag and @importsSucceeded > 0
        if @importsSucceeded is 1
          alertMsg = "#{alertMsg} The imported form has the tag
            “#{@importTag.get('name')}”."
        else
          alertMsg = "#{alertMsg} All imported forms have the tag
            “#{@importTag.get('name')}”."
      options =
        text: alertMsg
        confirm: false
      Backbone.trigger 'openAlertDialog', options

    cancelImportSelected: ->
      @stopSpin()
      @enableAllControls()

    # Gather all of the search filters (arrays) from all of the selected and
    # valid rows and issue one search request for duplicates. Both success and
    # failure may result in `@importSelected()` being called.
    searchForDuplicates: ->
      @disableAllControlsButStop()
      @duplicatesFound = []
      disjuncts = []
      for row in @rowViews
        if row.selected and row.valid
          disjuncts.push row.getCheckForDuplicatesFilter()
      if disjuncts.length > 0
        search =
          filter: ['or', disjuncts]
          order_by: ['Form', 'id', 'desc']
        # WARNING: allowing 10,000 results may be a very bad idea ...
        paginator = {page: 1, items_per_page: 10000}
        @dummyFormModel.search search, paginator
      else
        @importSelected()

    searchForDuplicatesSuccess: (responseJSON) ->
      if responseJSON.paginator.count > 0
        @duplicatesFound = responseJSON.items
      else
        @duplicatesFound = []
      @importSelected()

    searchForDuplicatesFail: (error) ->
      @duplicatesFound = []
      @notifyUserOfDuplicatesSearchFail()

    # Open a confirm dialog that notifies the user that search for possible
    # duplicates failed. They may, nevertheless, choose to continue with the
    # import.
    notifyUserOfDuplicatesSearchFail: ->
      options =
        text: "An error occured when attempting to search for duplicates for
          the selected forms. Click “Ok” to proceed with the import,
          understanding that you may be duplicating existing forms as a
          result. Click “Cancel” to abort the import."
        confirm: true
        confirmEvent: 'importSelected'
        cancelEvent: 'cancelImportSelected'
        eventTarget: @
      Backbone.trigger 'openAlertDialog', options

    purviewSelector: '.dative-widget-header, .dative-importer-import,
      .import-controls.container, .general-errors-container,
      .general-warnings-container'

    disableAllControls: ->
      @$(@purviewSelector)
        .find('button').button('disable').end()
        .find('select').selectmenu 'option', 'disabled', true
      @headerView.disableAllControls()
      # for rowView in @rowViews
      #   rowView.disableAllControls()

    disableAllControlsButStop: ->
      @disableAllControls()
      @$(@purviewSelector)
        .find('button.stop-import-selected-button')
        .button('enable')

    enableAllControls: ->
      @$(@purviewSelector)
        .find('button').button('enable').end()
        .find('select').selectmenu 'option', 'disabled', false
      @headerView.enableAllControls()
      # for rowView in @rowViews
      #   rowView.enableAllControls()

    searchForFilenames: ->
      @getFilenamesFromRowViews()
      if @filenames.length > 0
        search =
          filter: ["or", [
            ["File", "filename", "in", @filenames]
            ["File", "name", "in", @filenames]]]
          order_by: ["File", "id", "desc"]
        paginator = {page:1, items_per_page: @filenames.length}
        @dummyFileModel.search search, paginator
      else
        @validateSelectedMiddle()

    fileSearchFail: (responseJSON) ->
      @validateSelectedFinal()

    fileSearchSuccess: (responseJSON) ->
      @filenames2objects = {}
      if responseJSON.paginator.count > 0
        files = responseJSON.items
        for fo in files
          if fo.filename
            @filenames2objects[fo.filename] = fo
          if fo.name and fo.name isnt fo.filename
            @filenames2objects[fo.name] = fo
      @validateSelectedMiddle()

    # Aggregate all of the filenames from all of the selected row views.
    getFilenamesFromRowViews: ->
      filenames = {}
      for rowView in @rowViews
        if rowView.selected
          for filename in rowView.getFilenames()
            filenames[filename] = null
      @filenames = _.keys filenames

    # User has clicked the "Validate Selected" button.
    validateSelected: ->
      @spin 'validating'
      @defaultValidationState()
      @disableAllControls()
      @hideValidationContainers()
      # Instead of having all row views search for their own filenames on the
      # server, we collect them all in this method and search for them in bulk.
      # Success/failure in this request triggers a method that resolves the
      # validation.
      @searchForFilenames()

    # We have a map from filename strings to file objects, so we can continue
    # with CSV row validation. Give the map to each row view and trigger their
    # `@validate` methods, gathering any warnings and errors in the process.
    validateSelectedMiddle: ->
      for rowView, index in @rowViews
        if rowView.selected
          rowView.filenames2objects = @filenames2objects
          [rowWarnings, rowErrors, solutions] = rowView.validate()
          for warning in rowWarnings
            @addToRowWarnings warning, rowView.rowIndex
          for error in rowErrors
            @addToRowErrors error, rowView.rowIndex
          for solutionName, solutionMeta of solutions
            @addToSolutions solutionName, solutionMeta
      [@warnings, @errors] = @headerView.validate()
      @validateSelectedFinal()

    # Terminate the "Validate Selected" request.
    validateSelectedFinal: ->
      @displayWarnings()
      @displayErrors()
      @buttonify()
      @stopSpin()
      if @importPostValidation
        @importPostValidation = false
        validRows = (r for r in @rowViews when r.valid)
        if validRows.length > 0
          [warnCount, errorCount] = @getWarningsErrorsCounts()
          if warnCount > 0 or errorCount > 0
            @alertUserOfWarningsErrors warnCount, errorCount
          else
            @searchForDuplicates()
        else
          @enableAllControls()
          @stopSpin()
          Backbone.trigger 'csvFormImportNoneValid'
      else
        @enableAllControls()

    getWarningsErrorsCounts: ->
      [
        (@warnings.length + _.keys(@rowWarnings).length)
        (@errors.length + _.keys(@rowErrors).length)
      ]

    # Display a confirm dialog which lets the user abort the import if
    # they want to first deal with the warnings and errors.
    alertUserOfWarningsErrors: (warnCount, errorCount) ->
      if warnCount > 0 and errorCount > 0
        msg = "We have found #{errorCount}
          #{@utils.pluralizeByNum 'error', errorCount} and #{warnCount}
          #{@utils.pluralizeByNum 'warning', warnCount} in this CSV file."
      else if errorCount > 0
        msg = "We have found #{errorCount}
          #{@utils.pluralizeByNum 'error', errorCount} in this CSV file."
      else if warnCount > 0
        msg = "We have found #{warnCount}
          #{@utils.pluralizeByNum 'warning', warnCount} in this CSV file."
      options =
        text: "#{msg} Click “Import Anyway” to proceed with the import
          despite the warnings/errors. Click “Cancel Import” to abort the import
          and resolve the errors and warnings first."
        confirm: true
        confirmEvent: 'searchForDuplicates'
        cancelEvent: 'cancelImportSelected'
        eventTarget: @
        confirmButtonText: 'Import Anyway'
        cancelButtonText: 'Cancel Import'
      Backbone.trigger 'openAlertDialog', options

    hideValidationContainers: ->
      @$('.general-errors-container').hide()
      @$('.general-warnings-container').hide()

    displayWarnings: ->
      @$('button.toggle-warnings i')
        .removeClass 'fa-caret-down'
        .addClass 'fa-caret-right'
      @$('.general-warnings-container').show()
      warningsCount = @warnings.length
      rowWarningsCount = _.keys(@rowWarnings).length
      if warningsCount > 0 or rowWarningsCount > 0
        totalWarningsCount = warningsCount + rowWarningsCount
        warningsWord = @utils.pluralizeByNum 'Warning', totalWarningsCount
        @$('h1.warnings-header').show().find('.warnings-header-text')
          .text "#{totalWarningsCount} #{warningsWord}"
        @$('button.toggle-warnings').show()
        @$('button.fix-all-warnings').show()
        @$('h1.no-warnings-header').hide()
        @displayIndividualWarnings()
      else
        @$('h1.warnings-header').hide()
        @$('button.toggle-warnings').hide()
        @$('button.fix-all-warnings').hide()
        @$('div.general-warnings-list-wrapper').hide()
        @$('h1.no-warnings-header').show()

    displayErrors: ->
      @$('button.toggle-errors i')
        .removeClass 'fa-caret-down'
        .addClass 'fa-caret-right'
      @$('.general-errors-container').show()
      errorsCount = @errors.length
      rowErrorsCount = _.keys(@rowErrors).length
      if errorsCount > 0 or rowErrorsCount > 0
        totalErrorsCount = errorsCount + rowErrorsCount
        errorsWord = @utils.pluralizeByNum 'Error', totalErrorsCount
        @$('h1.errors-header').show().find('.errors-header-text')
          .text "#{totalErrorsCount} #{errorsWord}"
        @$('button.toggle-errors').show()
        @$('h1.no-errors-header').hide()
        @displayIndividualErrors()
      else
        @$('h1.errors-header').hide()
        @$('button.toggle-errors').hide()
        @$('div.general-errors-list-wrapper').hide()
        @$('h1.no-errors-header').show()

    # Display the errors for this row.
    displayIndividualErrors: ->
      $container = @$ 'ul.general-errors-list'
      fragment = document.createDocumentFragment()
      $template = @$('li.import-error-list-item').first()
      for msg, errorObject of @rowErrors
        rows = (i + 1 for i in errorObject.rows)
        $error = $template.clone().find('.error-text')
          .text("#{msg} (#{@utils.pluralizeByNum 'row', rows.length}
            #{rows.join ', '})").end()
        if errorObject.solution
          $error.find('button.error-solution').show()
            .attr 'data-solution-id', errorObject.solution.id
            .button label: errorObject.solution.name
        else
          $error.find('button.error-solution').hide()
        fragment.appendChild $error.get(0)
      for msg in @errors
        $error = $template.clone()
          .find('.error-text').text(msg).end()
          .find('button.error-solution').hide().end()
        fragment.appendChild $error.get(0)
      $container.html(fragment)
      @$('div.general-errors-list-wrapper').hide()

    # Display the warnings for this row.
    displayIndividualWarnings: ->
      $container = @$ 'ul.general-warnings-list'
      fragment = document.createDocumentFragment()
      $template = @$('li.import-warning-list-item').first()
      for msg, warningObject of @rowWarnings
        rows = (i + 1 for i in warningObject.rows)
        $warning = $template.clone().find('.warning-text')
          .text("#{msg} (#{@utils.pluralizeByNum 'row', rows.length}
            #{rows.join ', '})").end()
        if warningObject.solution
          $warning.find('button.warning-solution').show()
            .attr 'data-solution-id', warningObject.solution.id
            .button label: warningObject.solution.name
        else
          $warning.find('button.warning-solution').hide()
        fragment.appendChild $warning.get(0)
      for msg in @warnings
        $warning = $template.clone()
          .find('.warning-text').text(msg).end()
          .find('button.warning-solution').hide().end()
        fragment.appendChild $warning.get(0)
      $container.html(fragment)
      @$('div.general-warnings-list-wrapper').hide()

    addToRowWarnings: (warning, rowIndex) ->
      if warning.msg of @rowWarnings
        @rowWarnings[warning.msg].rows.push rowIndex
      else
        @rowWarnings[warning.msg] =
          solution: warning.solution
          rows: [rowIndex]

    addToRowErrors: (error, rowIndex) ->
      if error.msg of @rowErrors
        @rowErrors[error.msg].rows.push rowIndex
      else
        @rowErrors[error.msg] =
          solution: error.solution
          rows: [rowIndex]

    addToSolutions: (solutionName, solutionMeta) ->
      if solutionMeta.id not of @solutions
        solutionMeta.name = solutionName
        @solutions[solutionMeta.id] = solutionMeta

    togglePreviews: ->
      if @previewsVisible
        @previewsVisible = false
        @setPreviewSelectedButtonStateClosed()
        for rowView in @rowViews
          if rowView.selected
            rowView.hidePreview()
      else
        selectedCount = (v for v in @rowViews when v.selected).length
        # If we are about to preview very many rows/forms, prompt the user for
        # confirmation first because this can cause a big slowdown.
        if selectedCount > 100
          @showPreviewsConfirm selectedCount
        else
          @showPreviews()

    showPreviewsConfirm: (selectedCount) ->
      options =
        text: "Generating previews for all #{selectedCount} rows may take a very
          long time and may slow down your computer. Do you really want to do
          this?"
        confirm: true
        confirmEvent: "showPreviews"
      Backbone.trigger 'openAlertDialog', options

    showPreviews: ->
      @previewsVisible = true
      @setPreviewSelectedButtonStateOpen()
      for rowView in @rowViews
        if rowView.selected then rowView.showPreview()

    setPreviewSelectedButtonStateClosed: ->
      @$('button.preview-selected-button')
        .button label: 'Preview Selected'
        .tooltip content: 'View the selected rows as Dative forms (IGT display)'

    setPreviewSelectedButtonStateOpen: ->
      @$('button.preview-selected-button')
        .button label: 'Hide Previews'
        .tooltip content: 'Hide the previews'

    # Update the state of all of the buttons that operate over all selected CSV
    # rows, i.e, "Import All", "View All" and "Validate All". The "Import"
    # button indicates how many form rows are selected for import; we disable the
    # buttons if no rows are selected.
    allSelectedButtonsState: ->
      selectedCount = (v for v in @rowViews when v.selected).length
      totalCount = @rowViews.length
      @$('.import-selected-button-text').text "Import Selected (#{selectedCount} of
        #{totalCount})"
      if selectedCount is 0
        @$('button.import-selected-button').button 'disable'
        @$('button.preview-selected-button').button 'disable'
        @$('button.validate-selected-button').button 'disable'
      else
        @$('button.import-selected-button').button 'enable'
        @$('button.preview-selected-button').button 'enable'
        @$('button.validate-selected-button').button 'enable'

    selectAllFormsForImport: ->
      for rowView in @rowViews
        rowView.select()
      @allSelectedButtonsState()

    deselectAllFormsForImport: ->
      for rowView in @rowViews
        rowView.deselect()
      @allSelectedButtonsState()

    # Programmatically click the hidden button that open's the browser's "find
    # file" dialog.
    clickFileUploadInput: ->
      @$('[name=file-upload-input]').click()

    render: ->
      @$el.append @template(
        importTypes: @importTypes
        parseTranslations: @parseTranslations
        translationDelimiter: @translationDelimiter
        identifyTranslationCompatibilities: @identifyTranslationCompatibilities
      )
      @$target = @$ '.dative-importer-target'
      @guify()
      @$('div.dative-importer-preview').hide()
      @$('button.discard-file-button').hide()
      @$('div.import-preview-table-wrapper, div.general-warnings-list-wrapper, 
        div.general-errors-list-wrapper, input[name=translation_delimiter]')
          .css("border-color", @constructor.jQueryUIColors().defBo)
      @

    tooltipify: ->
      # @$('.dative-tooltip').tooltip position: @tooltipPositionLeft()
      @$('.dative-tooltip').tooltip()

    # Make the import type select into a jQuery selectmenu.
    # NOTE: the functions triggered by the open and close events are a hack so
    # that the menu data will be displayed in jQueryUI dialogs, which have a
    # higher z-index.
    selectmenuify: (selector='select')->
      @$(selector)
        .selectmenu
          width: 'auto'
          open: (event, ui) ->
            @selectmenuDefaultZIndex = $('.ui-selectmenu-open').first().zIndex()
            $('.ui-selectmenu-open').zIndex 1120
          close: (event, ui) ->
            $('.ui-selectmenu-open').zIndex @selectmenuDefaultZIndex
        .each (index, element) =>
          @transferClassAndTitle @$(element) # so we can tooltipify the selectmenu

    guify: ->
      @buttonify()
      @selectmenuify 'select.import-type'
      @tooltipify()

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {left: '-55%'}

    spin: (text='') ->
      @$('.spinner-container').first()
        .text text
        .spin @spinnerOptions()

    stopSpin: ->
      @$('.spinner-container').first()
        .text ''
        .spin false

    # We only allow CSV imports right now.
    importTypes:
      csv:
        mimeTypes: ['text/csv', 'application/vnd.ms-excel']
        label: 'CSV'

    # Handle the user selecting a file from their file system. In the
    # successful cases, this will result in the file being parsed as CSV and
    # then displayed in a table.
    # Note: the attributes of the `fileBLOB` object are `name`, `type`, `size`,
    # `lastModified` (timestamp), and `lastModifiedDate` (`Date` instance).
    handleFileSelect: (event) ->
      if @fileBLOB
        @defaultValidationState()
        @clearFileMetadata()
        @fileBLOB = null
        @importCSVArray = null
        @closeRowViews()
        @previewsVisible = false
        @setPreviewSelectedButtonStateClosed()
      fileBLOB = event.target.files[0]
      if fileBLOB
        importType = @$('select.import-type').val()
        @fileBLOB = fileBLOB
        filename = @fileBLOB.name
        @displayFileMetadata()
        if fileBLOB.type not in @importTypes[importType].mimeTypes
          @forbiddenFile @fileBLOB, importType
        else if not filename.split('.').shift()
          @invalidFilename @fileBLOB
        else
          reader = new FileReader()
          reader.onloadstart = (event) => @fileDataLoadStart event
          reader.onloadend = (event) => @fileDataLoadEnd event
          reader.onerror = (event) => @fileDataLoadError event
          reader.onload = (event) => @fileDataLoadSuccess event
          @spin 'loading file'
          do (reader) =>
            x = => reader.readAsText @fileBLOB
            setTimeout x, 50
      else
        Backbone.trigger 'fileSelectError'

    # Next to the "Choose file" button, display the file's name, its size and
    # it line count, if it has been CSV-parsed.
    displayFileMetadata: ->
      if @importCSVArray
        @$('span.import-file-name').text "#{@fileBLOB.name}
          (#{@utils.humanFileSize(@fileBLOB.size)},
          #{@importCSVArray.length} lines)"
      else
        @$('span.import-file-name').text "#{@fileBLOB.name}
          (#{@utils.humanFileSize(@fileBLOB.size)})"

    clearFileMetadata: -> @$('span.import-file-name').text ''

    # Tell the user that the file they tried to select for upload cannot be
    # used, given the selected import type.
    forbiddenFile: (fileBLOB, importType) ->
      if fileBLOB.type
        errorMessage = "Sorry, files of type #{fileBLOB.type} cannot be
          uploaded for #{importType}-type imports."
      else
        errorMessage = "The file you have selected has no recognizable
          type."
      Backbone.trigger 'fileSelectForbiddenType', errorMessage

    # Tell the user that the file they tried to select has an invalid filename.
    invalidFilename: (fileBLOB) ->
      errorMessage = "Sorry, the filename #{@fileBLOB.name} is not valid."
      Backbone.trigger 'fileSelectInvalidName', errorMessage

    fileDataLoadStart: (event) ->
      @defaultValidationState()
      @filenames = []
      @hideGeneralWarningsAndErrors()
      $previewDiv = @$ '.dative-importer-preview'
      if not $previewDiv.is ':visible' then $previewDiv.show()

    fileDataLoadEnd: (event) ->

    fileDataLoadError: (event) ->
      Backbone.trigger 'fileDataLoadError', @fileBLOB
      @stopSpin()

    # Handle the successful loading of a selected file.
    fileDataLoadSuccess: (event) ->
      fileData = event.target.result
      try
        @stopSpin()
        x = =>
          @spin 'parsing CSV file'
          @importCSVArray = @parseCSV fileData
          @$('.discard-file-button').show()
          @resetImportReportContainer()
          @hideImportReportContainer()
          @displayAsTable()
          @displayFileMetadata()
          @stopSpin()
        setTimeout x, 5
      catch
        Backbone.trigger 'importError'
        @stopSpin()

    # Return an object that maps CSV line indices to the names of the
    # corresponding (OLD) form attributes. This works only if the CSV file
    # contains a header line (i.e., line 1) that contains names that match OLD
    # form attribute names, e.g., "transcription", "translations", etc.
    getColumnLabelsFromCSVFile: ->
      formAttributes = FormModel::defaults()
      @columnLabels = []
      @firstLineIsHeader = true
      for headerValue in @importCSVArray[0]
        if headerValue of formAttributes
          @columnLabels.push headerValue
        else if headerValue.toLowerCase() of formAttributes
          @columnLabels.push headerValue.toLowerCase()
        else if @utils.regular2snake(headerValue) of formAttributes
          @columnLabels.push @utils.regular2snake headerValue
        else
          @columnLabels.push null
          # If any column header is unrecognizable, we categorize the import
          # file has not having a header line. We still use any headers we may
          # have gleaned though.
          @firstLineIsHeader = false
      if @firstLineIsHeader then @importCSVArray = @importCSVArray[1...]

    # Display the imported CSV file in a big table.
    displayAsTable: ->
      @getColumnLabelsFromCSVFile()

      @getHeaderView()
      @renderHeaderView()
      @listenToHeaderView()

      @getRowViews()
      @renderRowViews()
      @listenToRowViews()

      @headerView.columnHeaderChanged()
      @tooltipify()
      @allSelectedButtonsState()

    getHeaderView: ->
      @headerView = new CSVImportHeaderView
        columnLabels: @columnLabels

    renderHeaderView: ->
      @$('.dative-importer-preview div.import-preview-table').first()
        .find 'div.import-preview-table-head'
        .html @headerView.render().el
      @rendered @headerView

    snake2regular: (str) ->
      if str is null then 'no label' else @utils.snake2regular str

    getRowViews: ->
      if @rowViews.length > 0 then @closeCSVTableRowViews()
      columnLabelsHuman = (@snake2regular(l) for l in @columnLabels)
      for line, index in @importCSVArray
        rowView = new CSVImportRowView
          line: line
          rowIndex: index
          columnLabels: @columnLabels
          columnLabelsHuman: columnLabelsHuman
          stringToObjectMappers: @stringToObjectMappers
          formsCollection: @formsCollection
          translationDelimiter: @translationDelimiter
          parseTranslations: @parseTranslations
          identifyTranslationCompatibilities: @identifyTranslationCompatibilities
        @rowViews.push rowView

    closeCSVTableRowViews: ->
      for view in @rowViews
        view.close()
        @stopListening view
        @closed view
      @rowViews = []

    # Render the row views, one for each line in the to-be-imported CSV file.
    renderRowViews: ->
      fragment = document.createDocumentFragment()
      for view in @rowViews
        fragment.appendChild view.render().el
        @rendered view
      @$('.dative-importer-preview div.import-preview-table').first()
        .find 'div.import-preview-table-body'
        .html fragment

    # Set the column widths of the "table" (made up of <div>s), based on the
    # widths of the header cells. This is called whenever a selectmenu option
    # is changed in a header cell.
    setColumnWidths: (widths) ->
      for rowView in @rowViews
        rowView.setWidths widths

    columnLabelsChanged: (labels) ->
      @columnLabels = labels
      columnLabelsHuman = (@snake2regular(l) for l in @columnLabels)
      for rowView in @rowViews
        rowView.columnLabelsChanged @columnLabels, columnLabelsHuman

    # Parse a CSV string into an array of arrays.
    # This is a pretty cool implementation, but it's extremely slow with large
    # CSV files: attempting to parse a 8.6 MB 24,000-line CSV file caused the
    # browser to crash. Consider using PapaParse
    # (https://github.com/mholt/PapaParse).
    # See http://stackoverflow.com/a/12785546 for the source/origin of this
    # method.
    # TODO: write tests for this.
    parseCSV: (csv) ->
      reviver = (r, c, v) -> v
      chars = csv.split ''
      c = 0
      cc = chars.length
      table = []
      while c < cc
        row = []
        table.push row
        while c < cc and chars[c] not in ['\r', '\n']
          start = end = c
          if chars[c] is '"'
            start = end = ++c
            while c < cc
              if chars[c] is '"'
                if chars[c + 1] isnt '"'
                  break
                else
                  chars[++c] = ''
              end = ++c
            if chars[c] is '"' then ++c
            while c < cc and chars[c] not in ['\r', '\n', ',']
              ++c
          else
            while c < cc and chars[c] not in ['\r', '\n', ',']
              end = ++c
          row.push(reviver(table.length - 1, row.length,
            chars.slice(start, end).join('')))
          if ',' is chars[c] then ++c
        if chars[c] in ['\r', '\n'] then ++c
      (row for row in table when row.length > 0)

