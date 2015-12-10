define [
  './base'
  './form'
  './../models/form'
  './../templates/csv-import-row'
  './../utils/globals'
], (BaseView, FormView, FormModel, importRowTemplate, globals) ->


  # Specialized `FormView` sub-class that doesn't allow export or settings and
  # also has an "Import" button instead of a "Save" button.
  class FormViewForImport extends FormView

    excludedActions: [
      'history'
      'controls'
      'data'
      'settings'
      'export'
    ]

    initialize: (options) ->
      options.forImport = true
      super options


  # Import Row View
  # ---------------
  #
  # Controls a single CSV (table) row for form import. Controls the row's
  # "import", "preview" and "validate" buttons.

  class CSVImportRowView extends BaseView

    template: importRowTemplate

    initialize: (options) ->

      # An array of strings representing the row from the CSV file, given to us
      # by our parent.
      @line = options.line

      # The 0-based index of the CSV row that this view is controlling.
      @rowIndex = options.rowIndex

      # An array of column label strings; induced from the CSV file by our
      # parent view.
      @columnLabels = options.columnLabels

      # Our column labels in human-readable format, i.e., no snake_case.
      @columnLabelsHuman = options.columnLabelsHuman

      @formsCollection = options.formsCollection

      # Object that maps attribute names to objects that map string values of
      # relational attributes to corresponding (existing) relational objects.
      @stringToObjectMappers = options.stringToObjectMappers

      # Maps column labels to valid OLD form model values, generated based on
      # the state of the row in the DOM.
      @object = {}

      # We'll set to this using `@object`, after the user asks us to
      # validate (or view or import).
      @model = new FormModel({}, {collection: @formsCollection})
      @listenToModel()

      # This will hold the `FormView` sub-class instances used to display
      # previews of our to-be-imported form model `@model`.
      @formView = null

      # Validation may create warnings and/or errors. We store them in these:
      @warnings = []
      @errors = []

      # Solutions are ways of resolving warnings and/or errors.
      @solutions = {}

      # Maps file.filename and file.name values to existing file resource
      # objects. File resources are special because we have to search for
      # matches; our parent does that for us.
      @filenames2objects = {}

      # Will be `true` when we have rendered a `FormView` instance for our row.
      @previewRendered = false

      # When `@valid` is `null`, this row hasn't been validated yet; `true`
      # means it is valid (no errors), `false` means invalid.
      @valid = null

      # Whether our checkbox is selected, i.e., whether this row is selected
      # (e.g., for validation, import, etc.)
      @selected = true

      # This will be set to true when we want to issue a create request to the
      # server after a check for duplicates has returned no duplicates.
      @issueCreateRequestIfNoDuplicates = false

      # When set to `true`, this var will prevent the triggering of the
      # `Backbone`-wide event that causes the row import success notification
      # to pop up. With multi-row imports, such notifications are too
      # resource-intensive.
      @silentAddFormSuccess = false

      # We listen to ourself for an 'issueCreateRequest' event; the
      # alert/confirm dialog may trigger this when a user clicks "Ok",
      # consenting to perform an import despite the existence of possible
      # duplicates.
      @listenTo @, 'issueCreateRequest', @issueCreateRequestFromEvent

      # We listen to ourself for an 'cancelCreateRequestBecauseDuplicates'
      # event; the alert/confirm dialog may trigger this when a user clicks
      # "Cancel", indicating that they do not want to perform an import because
      # possible duplicates.
      @listenTo @, 'cancelCreateRequestBecauseDuplicates',
        @cancelCreateRequestBecauseDuplicates

    issueCreateRequestFromEvent: -> @issueCreateRequest()

    # Reset to our default state.
    resetState: ->
      @object = {}
      @model = new FormModel({}, {collection: @formsCollection})
      @listenToModel()
      @warnings = []
      @errors = []
      @solutions = {}
      @previewRendered = false
      @selected = true
      @valid = null
      @setStateNotValidated()

    listenToModel: ->
      @listenTo @model, "addFormStart", @addFormStart
      @listenTo @model, "addFormEnd", @addFormEnd
      @listenTo @model, "addFormFail", @addFormFail
      @listenTo @model, "addFormSuccess", @addFormSuccess
      @listenTo @model, 'searchSuccess', @searchForDuplicatesSuccess
      @listenTo @model, 'searchFail', @searchForDuplicatesFail

    events:
      'click button.preview-row':      'togglePreview'
      'click button.import-csv-row':   'import'
      'click button.validate-csv-row': 'validate'
      'focus .csv-value-cell':         'cellFocused'
      'blur .csv-value-cell':          'cellBlurred'
      'blur .csv-value-cell-text':     'cellTextBlurred'
      'keydown .csv-value-cell-text':  'cellTextKeyboard'
      'keydown .csv-value-cell':       'cellKeyboard'
      'dblclick .csv-value-cell':      'editCell'
      'keyup .csv-value-cell':         'cellKeyboardUp'
      'click i.select-for-import':     'selectClick'
      'click i.deselect-for-import':   'deselectClick'
      'keydown i.select-for-import':   'selectKey'
      'keydown i.deselect-for-import': 'deselectKey'
      'input div.csv-value-cell-text': 'cellValueChanged'

    # When the text in a cell changes, we signal that the new state of the row
    # has not been validated.
    cellValueChanged: ->
      @valid = null
      @setStateNotValidated()

    # Set this row's state to selected.
    select: ->
      @selected = true
      @$('i.select-for-import')
        .removeClass 'fa-square select-for-import'
        .addClass 'fa-check-square deselect-for-import'

    # User has clicked the select empty box button.
    selectClick: (event) ->
      @select().first().focus()
      @trigger 'rowSelected'

    # <Return> and <SpaceBar> both toggle a row's selected-ness.
    selectKey: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @select()

    # Set this row's state to deselected.
    deselect: ->
      @selected = false
      @$('i.deselect-for-import')
        .addClass 'fa-square select-for-import'
        .removeClass 'fa-check-square deselect-for-import'

    # User has clicked the deselect checkmark button.
    deselectClick: (event) ->
      @deselect().first().focus()
      @trigger 'rowDeselected'

    # <Return> and <SpaceBar> both toggle a row's selected-ness.
    deselectKey: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @deselect()

    # A focused cell has an inner black border.
    cellFocused: (event) ->
      @$(event.currentTarget).addClass 'cell-focused'

    # An un-focused cell has no inner black border.
    cellBlurred: (event) ->
      @$(event.currentTarget).removeClass 'cell-focused'

    # When a cell's text loses focus, it is no longer editable.
    cellTextBlurred: (event) ->
      $cellText = @$ event.currentTarget
      $cellText
        .text $cellText.text().trim()
        .attr 'contenteditable', 'false'
        .removeClass 'ui-corner-all'
        .closest('.csv-value-cell').css 'overflow', 'hidden'

    # The keyup event after a <Tab> press should not propagate because the
    # `ResourcesView` parent class does weird scroll stuff in response to that.
    cellKeyboardUp: (event) ->
      if event.which is 9 then @stopEvent event

    # Stop propogation of keydown events in the cell text <div>: we don't want
    # the down arrow to focus the cell below if we are typing text in a
    # contenteditable <div>.
    # Note: I was for a while only stopping propagation when the event was not
    # an arrow key: `if event.which not in [37..40]. However, true spreadsheet
    # behaviour is more complex than that ...
    cellTextKeyboard: (event) ->
      if event.which is 27
        @$(event.currentTarget).blur().closest('.csv-value-cell').focus()
      else
        event.stopPropagation()

    # Respond to keydown events in a cell: arrow keys and (Shift+)Tab/Enter
    # focus adjacent keys, as per regular spreadsheet app behavior.
    cellKeyboard: (event) ->
      switch event.which
        when 8 # Backspace deletes the text in a cell.
          @clearCellText event
          @cellValueChanged()
          @stopEvent event
        when 39 # right arrow to go right.
          @focusCellRight event
          @stopEvent event
        when 37 # left arrow to go left.
          @focusCellLeft event
          @stopEvent event
        when 38 # up arrow to go up.
          @focusCellAbove event
          @stopEvent event
        when 40 # down arrow to go down.
          @focusCellBelow event
          @stopEvent event
        when 9 # Shift+Tab goes left, Tab goes right.
          if event.shiftKey
            @focusCellLeft event
          else
            @focusCellRight event
          @stopEvent event
        when 13 # Shift+Enter goes up, Enter goes down.
          @editCell event
          # if event.shiftKey
          #   @focusCellAbove event
          # else
          #   @focusCellBelow event
          @stopEvent event
        else
          if event.which in @editKeys # alphanumeric keys and space lead to editing.
            @editCell event

    # Typing a content-ful key (letters, numbers and punctuation) when a cell
    # is focused will cause that cell to become editable.
    editKeys: [65..90].concat [48..57], [32]

    # Given an event `event` on a cell, return that cell's index in the row.
    getCellIndex: (event) -> @$('.csv-value-cell').index @$(event.currentTarget)

    # Focus a cell, given its index.
    focusCell: (cellIndex) ->
      @$('.csv-value-cell').eq(cellIndex).focus()

    # Remove the text in a cell.
    clearCellText: (event) ->
      @$(event.currentTarget).find('.csv-value-cell-text').first().text ''

    # Edit a cell: make it "contenteditable", focus it and select all of it.
    # Note that when a keydown even calls this, the text currently in the cell
    # will be replaced by the character of the keydown event.
    editCell: (event) ->
      $cell = @$(event.currentTarget)
      if $cell.hasClass 'ui-state-disabled' then return
      $cell.css 'overflow', 'initial'
      $cellText = $cell.find('.csv-value-cell-text').first()
      $cellText
        .attr 'contenteditable', 'true'
        .addClass('ui-corner-all')
        .focus()
      @selectText $cellText

    # Select all of the text in the jQuery element `$cellText`.
    selectText: ($cellText) ->
      element = $cellText[0]
      if document.body.createTextRange
        range = document.body.createTextRange()
        range.moveToElementText(element)
        range.select()
      else if window.getSelection
        selection = window.getSelection()
        range = document.createRange()
        range.selectNodeContents element
        selection.removeAllRanges()
        selection.addRange range

    # Focus the cell to the RIGHT of the one that `event` was triggered on.
    focusCellRight: (event) ->
      cellIndex = @getCellIndex event
      @$('.csv-value-cell').eq(cellIndex + 1).focus()

    # Focus the cell to the LEFT of the one that `event` was triggered on.
    focusCellLeft: (event) ->
      cellIndex = @getCellIndex event
      newIndex = cellIndex - 1
      if newIndex >= 0 then @$('.csv-value-cell').eq(cellIndex - 1).focus()

    # Focus the cell ABOVE the one that `event` was triggered on. Note: we
    # trigger an event and let our parent view delegate this to another row.
    focusCellAbove: (event) ->
      cellIndex = @getCellIndex event
      @trigger 'focusCell', [(@rowIndex - 1), cellIndex]

    # Focus the cell BELOW the one that `event` was triggered on.
    focusCellBelow: (event) ->
      cellIndex = @getCellIndex event
      @trigger 'focusCell', [(@rowIndex + 1), cellIndex]

    render: ->
      @$el.html(@template({
        line: @line
        rowIndex: @rowIndex
        valid: @valid
        columnLabelsHuman: @columnLabelsHuman
        selected: @selected}))
      @bordercolors()
      @buttonify()
      @

    # Give theme-appropriate border colors to bordered elements.
    bordercolors: ->
      @$('.import-preview-table-cell, .import-preview-table-row,
        .import-preview-table-row-under, .csv-value-cell-text')
          .css("border-color", @constructor.jQueryUIColors().defBo)

    clearErrorsAndWarningsInDOM: ->
      @$('.import-errors-list, .import-warnings-list').html ''
      @$('.import-preview-table-row-under').hide()

    # Validate the data in this row, with a view to creating a form resource
    # from it. Return an array of warnings and an array of errors. Display any
    # warnings/errors below the row. The primary side-effects here are the
    # creation of `@model` and the setting of `@valid`.
    validate: ->
      @hidePreview()
      @resetState()
      @clearErrorsAndWarningsInDOM()
      @disableAllControls()
      @getObjectFromDOM()
      @removeUneditableAttributes()
      @fix() # fixes relational values and dates.
      @model.set @object
      @modelValidation()
      @displayWarningsAndErrors()
      @enableAllControls()
      if @errors.length > 0 then @valid = false else @valid = true
      [@warnings, @errors, @solutions]

    # If we have warngins or errors, display them.
    displayWarningsAndErrors: ->
      if @warnings.length > 0 or @errors.length > 0
        @$('.import-preview-table-row-under').show()
        @displayErrors()
        @displayWarnings()
        if @errors.length > 0 then @setStateInvalid() else @setStateValid()
      else
        @$('.import-preview-table-row-under').hide()
        @setStateValid()

    setStateInvalid: ->
      @$('button.validate-csv-row')
        .tooltip content: 'Check for potential warnings and errors prior to
          importing this row. This row is NOT VALID.'
      @$('i.validation-status')
        .removeClass 'fa-check-circle ui-state-ok'
        .addClass 'fa-times-circle ui-state-error-color'
        .show()

    setStateValid: ->
      @$('button.validate-csv-row')
        .tooltip content: 'Check for potential warnings and errors prior to
          importing this row. This row is VALID.'
      @$('i.validation-status')
        .removeClass 'fa-times-circle ui-state-error-color'
        .addClass 'fa-check-circle ui-state-ok'
        .show()

    setStateNotValidated: ->
      @$('button.validate-csv-row')
        .tooltip content: 'Check for potential warnings and errors prior to
          importing this row.'
      @$('i.validation-status').hide()

    # Display the errors for this row.
    displayErrors: ->
      $container = @$ 'div.import-preview-table-row-errors-container'
      if @errors.length > 0
        fragment = document.createDocumentFragment()
        $template = @$('li.import-error-list-item').first()
        for error in @errors
          $error = $template.clone()
            .find('.error-text').text(error.msg).end()
          if error.solution
            $error.find('button.error-solution').show()
              .attr 'data-solution-id', error.solution.id
              .button label: error.solution.name
          else
            $error.find('button.error-solution').hide()
          fragment.appendChild $error.get(0)
        $container.find('.import-errors-list').html(fragment)
        $container.show()
      else
        $container.hide()

    # Display the warnings for this row.
    displayWarnings: ->
      $container = @$ 'div.import-preview-table-row-warnings-container'
      if @warnings.length > 0
        fragment = document.createDocumentFragment()
        $template = @$('li.import-warning-list-item').first()
        for warning in @warnings
          $warning = $template.clone()
            .find('.warning-text').text(warning.msg).end()
          if warning.solution
            $warning.find('button.warning-solution').show()
              .attr 'data-solution-id', warning.solution.id
              .button label: warning.solution.name
          else
            $warning.find('button.warning-solution').hide()
          fragment.appendChild $warning.get(0)
        $container.find('.import-warnings-list').html(fragment)
        $container.show()
      else
        $container.hide()

    # Validate our `FormModel` (populated by our row data). Add any errors to
    # `@errors`.
    modelValidation: ->
      errors = @model.validate()
      if errors
        for attr, errorMsg of errors
          @addToErrors(
            msg: "#{attr}: #{errorMsg}"
            solution: null
          )

    addToWarnings: (warning) ->
      if not _.findWhere(@warnings, msg: warning.msg)
        @warnings.push warning

    addToErrors: (error) ->
      if not _.findWhere(@errors, msg: error.msg)
        @errors.push error

    # Fix date values and relational values in `@object`
    fix: ->
      @fixDateElicited()
      @fixTranslations()
      @fixManyToOne()
      @fixManyToMany()

    # Populate `@object` given the text in our row in the DOM.
    getObjectFromDOM: ->
      @object = {}
      @$('div.csv-value-cell').each (i, e) =>
        @object[@columnLabels[i]] = @$(e).text()

    # Remove the uneditable form attributes (e.g., id) from our `@object`.
    removeUneditableAttributes: ->
      for attr of @object
        if attr not in FormModel::editableAttributesOLD
          delete @object[attr]

    closeExistingFormView: ->
      if @formView
        @formView.close()
        @stopListening @formView
        @closed @formView
        @formView = null

    togglePreview: ->
      if @$('.import-preview-table-row-display-container').is ':visible'
        @hidePreview()
      else
        @showPreview()

    # The user has clicked on the Hide" button of a CSV form row. So we hide it.
    hidePreview: ->
      @previewButtonStateClosed()
      @$('.import-preview-table-row-display-container')
        .slideUp complete: =>
          @$('.import-preview-table-row-under').hide()

    # The user has clicked on the "Preview" button of a CSV form row. So, we
    # attempt to display the to-be-imported form using a `FormViewForImport`
    # instance.
    showPreview: ->
      $parentContainer = @$ '.import-preview-table-row-under'
      $container = @$ '.import-preview-table-row-display-container'
      if @valid is null then @validate()
      @previewButtonStateOpen()
      if @valid and @previewRendered
        $parentContainer.show()
        $container.slideDown()
      else
        @closeExistingFormView()
        @formView = new FormViewForImport model: @model
        @formView.expanded = true
        @formView.dataLabelsVisible = true
        @formView.effectuateExpanded()
        @listenTo @formView, "newFormView:hide", @hidePreview
        $parentContainer.show()
        $container.hide()
          .html @formView.render().el
          .slideDown()
        @rendered @formView
        @previewRendered = true

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {left: '0%', top: '75%'}

    spin: ->
      @$('div.index-cell div.csv-row-spinner').first().spin @spinnerOptions()

    stopSpin: ->
      @$('div.index-cell div.csv-row-spinner').first().spin false

    # The user has clicked on the "Import" button of this CSV form row.
    import: ->
      @spin()
      @validate()
      if @valid
        @issueCreateRequestIfNoDuplicates = true
        @checkForDuplicates()
      else
        @stopSpin()

    # Check whether the server already contains the form that this row may
    # attempt to import.
    checkForDuplicates: ->
      search = @getCheckForDuplicatesSearch()
      paginator = {page: 1, items_per_page: 10}
      @model.search search, paginator

    # Issue a create request to the server; i.e., really import the form
    # encoded in this row.
    issueCreateRequest: ->
      @spin()
      Backbone.trigger 'closeAllResourceDisplayerDialogs'
      @model.collection.addResource @model

    searchForDuplicatesSuccess: (responseJSON) ->
      @stopSpin()
      if @issueCreateRequestIfNoDuplicates
        @issueCreateRequestIfNoDuplicates = false
        if responseJSON.paginator.count > 0
          @displayDuplicatesInDialogBoxes responseJSON.items
          @notifyUserOfDuplicates responseJSON.paginator.count
        else
          @issueCreateRequest()

    # Show the first n (= 2) duplicates in dialog boxes.
    displayDuplicatesInDialogBoxes: (duplicatesArray) ->
      Backbone.trigger 'closeAllResourceDisplayerDialogs'
      for duplicateFormObject in duplicatesArray[...2]
        duplicateModel = new FormModel duplicateFormObject
        Backbone.trigger 'showResourceModelInDialog', duplicateModel, 'form'

    closeAllResourceDisplayerDialogs: ->
      Backbone.trigger 'closeAllResourceDisplayerDialogs'

    # User has chosen not to import because of the presence of duplicates. We
    # close any resource dialogs that are open and we mark the row as not
    # imported because of duplicates.
    cancelCreateRequestBecauseDuplicates: ->
      Backbone.trigger 'closeAllResourceDisplayerDialogs'
      @setImportStateCanceledBecauseDuplicates()

    # Open a confirm dialog that notifies the user that potential duplicates
    # have been found. User action should then determine whether or not we
    # proceed with the import request.
    notifyUserOfDuplicates: (duplicatesCount) ->
      options =
        text: "We found #{duplicatesCount} possible
          #{@utils.pluralizeByNum 'duplicate', duplicatesCount} for the form in
          row #{@rowIndex + 1}. (See the dialog box(es).) Click “Ok” to
          proceed with the import anyway. Click “Cancel” to abort the import."
        confirm: true
        confirmEvent: "issueCreateRequest"
        cancelEvent: 'cancelCreateRequestBecauseDuplicates'
        eventTarget: @
      Backbone.trigger 'openAlertDialog', options

    # Open a confirm dialog that notifies the user that the attempt to search
    # for potential duplicates resulted in an error. The user may,
    # nevertheless, click "Ok" in order to proceed with the import request.
    notifyUserOfDuplicateSearchError: ->
      options =
        text: "An error occured when attempting to search for duplicates for
          the form in row #{@rowIndex + 1}. Click “Ok” to proceed with the
          import, understanding that you may be duplicating an existing form as
          a result. Click “Cancel” to abort the import."
        confirm: true
        confirmEvent: "issueCreateRequest"
        eventTarget: @
      Backbone.trigger 'openAlertDialog', options

    # Something went wrong when attempting to search for duplicates
    searchForDuplicatesFail: (error) ->
      @stopSpin()
      if @issueCreateRequestIfNoDuplicates
        @issueCreateRequestIfNoDuplicates = false
        @notifyUserOfDuplicateSearchError()

    # Return an OLD-style search object that can be used to search for
    # duplicates of this to-be-imported row/form on the server.
    # NOTE: because of how OLD search works there will, on the rare occasion,
    # be false matches returned; this is because there is no guarantee that the
    # matching translation transcriptions and translation grammaticalities
    # correspond to the same translation resources. This is acceptable for now.
    getCheckForDuplicatesSearch: ->
      search =
        filter: @getCheckForDuplicatesFilter()
        order_by: ["Form", "id", "desc"]
      search

    getCheckForDuplicatesFilter: ->
      crucialAttrs = ['phonetic_transcription',
        'narrow_phonetic_transcription', 'transcription', 'morpheme_break',
        'morpheme_gloss', 'grammaticality']
      conjuncts = []
      for attr in crucialAttrs
        conjuncts.push ['Form', attr, '=', @model.get(attr).normalize('NFD')]
      for translation in @model.get('translations')
        conjuncts.push(['Form', 'translations', 'transcription', '=',
          translation.transcription.normalize('NFD')])
        conjuncts.push(['Form', 'translations', 'grammaticality', '=',
          translation.grammaticality.normalize('NFD')])
      ["and", conjuncts]

    # The import (i.e., create/POST) request to the server failed.
    # Here we add the server's errors to our own and display them. We must have
    # missed something if client-side validation passed...
    addFormFail: (errors) ->
      @silentAddFormSuccess = false
      if errors
        for attr, errorMsg of errors
          @addToErrors(
            msg: "#{attr}: #{errorMsg}"
            solution: null
          )
      @displayWarningsAndErrors()
      Backbone.trigger 'csvFormImportFail', (@rowIndex + 1)
      @trigger 'importAttemptTerminated', false
      @setImportStateFailed()
      @stopSpin()

    # The import (i.e., create/POST) request to the server succeeded.
    addFormSuccess: (formModel) ->
      if @silentAddFormSuccess
        @silentAddFormSuccess = false
      else
        Backbone.trigger 'csvFormImportSuccess', (@rowIndex + 1),
          formModel.get('id')
      @trigger 'importAttemptTerminated', true
      @setImportStateSucceeded()
      @stopSpin()

    addFormStart: ->

    addFormEnd: ->

    setImportStateFailed: ->
      @$('button.import-csv-row')
        .tooltip content: 'Import just this form. Last import attempt FAILED.'
      @$('i.import-status')
        .removeClass 'fa-check-circle ui-state-ok fa-exclamation-circle'
        .addClass 'fa-times-circle ui-state-error-color'
        .show()

    setImportStateCanceledBecauseDuplicates: ->
      @$('button.import-csv-row').tooltip content: 'Import just this form.
        Last attempt canceled because possible duplicates found.'
      @$('i.import-status')
        .removeClass 'fa-times-circle ui-state-error-color fa-check-circle
          ui-state-ok'
        .addClass 'fa-exclamation-circle'
        .show()

    setImportStateSucceeded: ->
      @$('button.import-csv-row').tooltip content: 'Import just this form.
        ALREADY IMPORTED.'
      @$('i.import-status')
        .removeClass 'fa-times-circle ui-state-error-color
          fa-exclamation-circle'
        .addClass 'fa-check-circle ui-state-ok'
        .show()

    setImportStateNotTried: ->
      @$('button.import-csv-row').tooltip content: 'Import just this form.'
      @$('i.import-status').hide()

    # When we are not displaying a `FormView` instance, show "Preview" button.
    previewButtonStateClosed: ->
      @$('button.preview-row')
        .button label: 'Preview'
        .tooltip content: 'View this form in IGT format'

    # When we are not displaying a `FormView` instance, show "Hide" button.
    previewButtonStateOpen: ->
      @$('button.preview-row')
        .button label: 'Hide'
        .tooltip content: 'Hide the IGT-formatted display of this form'

    # Our parent view has told us that our column labels have changed.
    columnLabelsChanged: (labels, labelsHuman) ->
      @columnLabels = labels
      @columnLabelsHuman = labelsHuman
      @$('.csv-value-cell').each (i, e) =>
        $e = @$ e
        label = @columnLabels[i]
        $e.attr 'title', @columnLabelsHuman[i]
        if label in FormModel::editableAttributesOLD
          $e.removeClass 'ui-state-disabled'
        else
          $e.addClass 'ui-state-disabled'

    # Convert user-supplied yyyy-mm-dd dates to dd/mm/yyyy format.
    fixDateElicited: ->
      if @object.date_elicited
        @object.date_elicited =
          @utils.convertDateISO2mdySlash @object.date_elicited

    getGrammaticalities: ->
      result = ['*', '?', '#']
      if globals.oldApplicationSettings
        try
          grammaticalities =
            globals.oldApplicationSettings.get('grammaticalities').split(',')
          result = grammaticalities
      result

    # Parse `translationString` to a grammaticality prefix and a transcription
    # suffix.
    parseTranslationString: (translationString, grammaticalities) ->
      grammaticality = ''
      for gr in grammaticalities
        if @utils.startsWith translationString, gr
          grammaticality = gr
          break
      if grammaticality.length is translationString.length
        grammaticality = ''
      [translationString[grammaticality.length..], grammaticality]

    # Convert translations-as-string to translations-as-array-of-objects.
    # Note: assumes that translations are delimited by a semicolon. This is
    # potentially a problematic assumption and should be user-configurable.
    fixTranslations: ->
      # Get valid grammaticality values, sorted from longest to shortest.
      grammaticalities = @getGrammaticalities().sort (x, y) -> y.length - x.length
      if 'translations' of @object
        translationsString = @object.translations
        translationsArray = (t.trim() for t in translationsString.split(';'))
        newTranslations = []
        for translationString in translationsArray
          [transcription, grammaticality] =
            @parseTranslationString translationString, grammaticalities
          newTranslations.push
            transcription: transcription
            grammaticality: grammaticality
        @object.translations = newTranslations

    # Given a form field label (`attr`), return a resource name.
    attr2resource: (attr) ->
      resource = @relationalAttributes2resources[attr]
      if resource then resource else attr

    # Map field labels to resource names.
    relationalAttributes2resources:
      elicitation_method: 'elicitationMethod'
      elicitor: 'user'
      source: 'source'
      speaker: 'speaker'
      syntactic_category: 'syntacticCategory'
      verifier: 'user'
      tags: 'tag'
      files: 'file'

    # Return a "solution" object that will help us to create a resource for the
    # form attribute `attr` using the value `val`.
    getCreateResourceSolution: (attr, val) ->
      resource = @attr2resource attr
      name = "Create #{@utils.camel2regular resource} “#{val}”"
      if name not of @solutions
        @solutions[name] =
          id: @guid()
          resource: resource
          val: val
          type: 'create'
      [name, @solutions[name].id]

    # Try to convert many-to-one string values to objects. Delete these values
    # if this is not possible.
    fixManyToOne: ->
      for attr, val of @object
        if val and attr in FormModel::manyToOneAttributesOLD
          if attr of @stringToObjectMappers
            # For some reason, the pre-generated string reps of object values
            # are sometimes wrapped in double quotation marks (?!) ... hence
            # the odd predicate in the list comprehension below.
            matches = (p for p in @stringToObjectMappers[attr] \
              when p[0] in [val, "\"#{val}\""])
            if matches.length > 0
              @object[attr] = matches[0][1]
            else
              [name, id] = @getCreateResourceSolution attr, val
              warningObject =
                msg: "Unable to use “#{val}” as a value for
                  #{@utils.snake2regular attr}"
                solution:
                  name: name
                  id: id
              @addToWarnings warningObject
              delete @object[attr]
          else
            [name, id] = @getCreateResourceSolution attr, val
            warningObject =
              msg: "Unable to use “#{val}” as a value for
                #{@utils.snake2regular attr}"
              solution:
                name: name
                id: id
            @addToWarnings warningObject
            delete @object[attr]

    # Create a resource on the server, given the string `val` and the Form
    # attribute `attr`.
    # TODO: this shouldn't be a method. The purpose of this is so that warnings
    # and errors can come with buttons that, when clicked, cause us to try to
    # fix the warning/error, e.g., by creating a tag or other resource.
    createResource: (val, attr) ->
      console.log "You want to create a resource for the form attribute #{attr}
        using the string value #{val}"

    # Try to convert many-to-many string values to arrays of objects. Delete
    # these values if this is not possible.
    fixManyToMany: ->
      @parseTagsString()
      @parseFilesString()
      for attr, val of @object
        if val and attr not in ['tags', 'files'] and
        attr in FormModel::manyToManyAttributesOLD
          [name, id] = @getCreateResourceSolution attr, val
          warningObject =
            msg: "Unable to use “#{val}” as a value for the many-to-many
              attribute #{attr}"
            solution:
              name: name
              id: id
          @addToWarnings warningObject
          delete @object[attr]

    # Parse a string representation of an array of tags-as-objects. Assume that
    # commas delimit tags and require that tags exist as a resource in the
    # system already.
    parseTagsString: ->
      if not @object.tags then return
      tagsString = @object.tags
      tagsArray = (tn.trim() for tn in @object.tags.split ',')
      tagsToBeImported = []
      unrecognizedTags = []
      existingTags = globals.get('tags').data
      for tagName in tagsArray
        tagObject = _.findWhere existingTags, {name: tagName}
        if tagObject
          tagsToBeImported.push tagObject
        else
          unrecognizedTags.push tagName
      if tagsToBeImported.length > 0
        @object.tags = tagsToBeImported
      else
        warningObject =
          msg: "Unable to use “#{tagsString}” as a value for the many-to-many
            attribute tags"
          solution: null
        @addToWarnings warningObject
        @object.tags = []
      for tag in unrecognizedTags
        [name, id] = @getCreateResourceSolution 'tags', tag
        warningObject =
          msg: "Unable to recognize the tag “#{tag}” in “#{tagsString}”."
          solution:
            name: name
            id: id
        @addToWarnings warningObject

    # Convert the files string to an array of file names (assuming they're
    # delimited by commas).
    getFilesStringAsArray: ->
      if @object.files
        try
          (fn.trim() for fn in @object.files.split ',')
        catch
          []
      else
        []

    # Parse a string representation of this CSV row's `files` column to an
    # array of file objects.
    parseFilesString: ->
      filesString = @object.files
      @object.files = @getFilesStringAsArray()
      if @object.files.length is 0 then return
      filesToBeImported = []
      unrecognizedFiles = []
      for filename in @object.files
        fileObject = @filenames2objects[filename]
        if fileObject
          filesToBeImported.push fileObject
        else
          unrecognizedFiles.push filename
      if filesToBeImported.length > 0
        @object.files = filesToBeImported
      else
        warningObject =
          msg: "Unable to use “#{filesString}” as a value for the
            many-to-many attribute files"
          solution: null
        @addToWarnings warningObject
        @object.files = []
      for file in unrecognizedFiles
        [name, id] = @getCreateResourceSolution 'files', file
        warningObject =
          msg: "Unable to recognize the file “#{file}” in
            “#{filesString}”."
          solution:
            name: name
            id: id
        @addToWarnings warningObject

    # Our parent calls this in order to gather all of the filenames before
    # searching for them. The parent then gives us an object mapping these
    # names to their matching objects: `@filenames2objects`.
    getFilenames: ->
      @getObjectFromDOM()
      @getFilesStringAsArray()

    disableAllControls: ->
      @$('button').each (i, e) =>
        if @$(e).button 'instance'
          @$(e).button 'disable'
      @$('select').selectmenu 'option', 'disabled', true

    enableAllControls: ->
      @$('button').each (i, e) =>
        if @$(e).button 'instance'
          @$(e).button 'enable'
      @$('select').selectmenu 'option', 'disabled', false
      if @errors.length > 0
        @disableImportButton()
      else
        @enableImportButton()

    enableImportButton: -> @$('button.import-csv-row').button 'enable'

    disableImportButton: -> @$('button.import-csv-row').button 'disable'

    # Our parent view calls this, using the colum widths that the header view
    # has given it. The column widths are based on the column label
    # selectmenus.
    setWidths: (widths) ->
      @$('.csv-value-cell').each (i, e) =>
        @$(e).css
          'min-width': "#{widths[i]}px"
          'max-width': "#{widths[i]}px"

