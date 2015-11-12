define [
  './base'
  './form'
  './exporter-collection-csv'
  './../models/form'
  './../models/file'
  './../collections/forms'
  './../utils/globals'
  './../templates/csv-import'
], (BaseView, FormView, ExporterCollectionCSVView, FormModel, FileModel,
  FormsCollection, globals, importerTemplate) ->

  # TODO: create Backbone.View sub-classes for CSV rows: there is too much raw
  # HTML and jQuery hairiness in here.
  # TODO: reduce the `.html` calls by using document fragments.

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
  # Other features:
  #
  # - preview of to-be-imported forms
  # - validation (based on FormModel.validate)
  # - warnings of "un-parse-able" string data (e.g., source values that cannot
  #   be parsed to objects)
  # - table display of CSV import with editable cells (so that warnings can be
  #   turned off and validation cleared)
  # - selective import: manually select subset of forms in import file for
  #   finalized import.

  class CSVImportView extends BaseView

    template: importerTemplate

    initialize: ->
      @hasBeenRendered = false
      @warnings = {}
      @errors = {}
      @formsCollection = new FormsCollection()
      @renderedFormViews = {}
      @importCSVArray = null
      @fileBLOB = null
      @filenames = {}
      @formObjects = {}

      @dummyFileModel = new FileModel()
      @listenTo @dummyFileModel, 'searchSuccess', @fileSearchSuccess
      @listenTo @dummyFileModel, 'searchFail', @fileSearchFail

      # These are used to get the possible values for form relational fields
      # and to get info on what fields are user-editable.
      @dummyFormModel = new FormModel()
      @dummyFormView = new FormView model: @dummyFormModel
      @listenTo @dummyFormModel, 'getNewFormDataSuccess',
        @getStringToObjectMappers

      # Since we will be importing forms, we need the data from the server that
      # tells us what the relational values of forms can be, i.e., possible
      # speakers, users, etc. Assuming the call to `getNewResourceData` is
      # successful, the `globals` `Backbone.Model` instance will have
      # attributes for `speakers`, etc.
      @dummyFormView.model.getNewResourceData()

      @listenTo Backbone, 'importer:toggle', @toggle
      @listenTo Backbone, 'importer:openTo', @openTo

    events:
      'click .choose-import-file-button':         'clickFileUploadInput'
      'change [name=file-upload-input]':          'handleFileSelect'
      'click button.select-all-for-import':       'selectAllFormsForImport'
      'click button.select-none-for-import':      'deselectAllFormsForImport'
      'click i.select-for-import':                'selectFormForImport'
      'click i.deselect-for-import':              'deselectFormForImport'
      'keydown i.select-for-import':              'keydownSelectFormForImport'
      'keydown i.deselect-for-import':            'keydownDeselectFormForImport'
      'selectmenuchange .column-header':          'columnHeaderChanged'
      'click button.import-csv-row':              'importSingleCSVRow'
      'click button.view-csv-row':                'viewSingleCSVRow'
      'click button.validate-csv-row':            'validateSingleCSVRow'
      'click button.import-selected-button':      'importSelectedCSVRows'
      'click button.view-selected-button':        'viewSelectedCSVRows'
      'click button.validate-selected-button':    'validateSelectedCSVRows'
      'click button.hide-import-widget':          'hideMe'
      'click button.discard-file-button':         'discardFile'

    # User has clicked on the "X" button next to the "Choose File" button,
    # indicating that they no longer want to import from this file.
    discardFile: ->
      @spin()
      x = =>
        @clearFileMetadata()
        @$('.import-preview-table-head').html ''
        @$('.import-preview-table-body').html ''
        @fileBLOB = null
        @importCSVArray = null
        @closeRenderedFormViews()
        @$('.dative-importer-preview').slideUp()
        @$('button.discard-file-button').hide()
        @stopSpin()
      setTimeout x, 5

    hideMe: -> @trigger 'hideMe'

    # Display the errors for a specific row, given its index.
    displayErrorsForRow: (rowIndex) ->
      @displayWarningsOrErrorsForRow 'error', rowIndex

    # Display the warnings for a specific row, given its index.
    displayWarningsForRow: (rowIndex) ->
      @displayWarningsOrErrorsForRow 'warning', rowIndex

    # Display the warnings/errors (based on `type`) for a specific row, given
    # its index.
    displayWarningsOrErrorsForRow: (type, rowIndex) ->
      stateClass = if type is 'error' then 'error' else 'highlight'
      $container = @$("div.import-preview-table-row-#{type}s-container.\
        form-for-import-#{rowIndex}")
      $container.show()
      array = @["#{type}s"][rowIndex]
      if array and array.length > 0
        len = array.length
        $container
          .find(".#{type}s-header")
            .addClass "ui-state-#{stateClass}"
            .removeClass "ui-state-ok"
            .find(".#{type}s-header-icon")
              .addClass 'fa-exclamation-triangle'
              .removeClass 'fa-check-circle'
              .end()
            .find(".#{type}s-header-text")
              .text("#{len} #{@utils.pluralizeByNum type, len}")
              .end()
            .end()
          .find(".#{type}s-inner-container").html(
            @["get#{@utils.capitalize type}HTML"](array))
      else
        $container
          .find(".#{type}s-header")
            .removeClass "ui-state-#{stateClass}"
            .addClass "ui-state-ok"
            .find(".#{type}s-header-icon")
              .removeClass 'fa-exclamation-triangle'
              .addClass 'fa-check-circle'
              .end()
            .find(".#{type}s-header-text")
              .text("No #{@utils.pluralize type}")
              .end()
            .end()
          .find(".#{type}s-inner-container").html ''

    # Display the errors stored in `@errors`
    displayGeneralErrors: ->
      @displayGeneralWarningsOrErrors 'error'

    # Display the warnings stored in `@warnings`
    displayGeneralWarnings: ->
      @displayGeneralWarningsOrErrors 'warning'

    # Display the warnings or errors stored in `@warnings` or in `@errors`,
    # based on the value of `type`.
    displayGeneralWarningsOrErrors: (type) ->
      stateClass = if type is 'error' then 'error' else 'highlight'
      $container = @$ ".general-#{type}s-container"
      $container.show()
        .find(".#{type}s-inner-container").html ''
      lengths = (a.length for a in _.values(@["#{type}s"]))
      count = _.reduce(lengths, ((memo, num) -> memo + num), 0)

      rowIssues = {}
      for locus, issueArray of @["#{type}s"]
        if locus isnt 'general'
          for issue in issueArray
            if issue.msg of rowIssues
              rowIssues[issue.msg].rows.push locus
            else
              rowIssues[issue.msg] =
                solution: issue.solution
                rows: [locus]
      newRowIssues = []
      for issueMsg, issue of rowIssues
        newRowIssues.push
          solution: issue.solution
          msg: "#{issueMsg}
            (#{@utils.pluralizeByNum 'row', issue.rows.length}
            #{issue.rows.join ', '})"

      if 'general' of @["#{type}s"]
        for issue in @["#{type}s"].general
          newRowIssues.push issue

      if newRowIssues.length > 0
        $container.find(".#{type}s-inner-container")
          .html @["get#{@utils.capitalize type}HTML"](newRowIssues)

      if count > 0
        $container.find(".#{type}s-header")
          .addClass "ui-state-#{stateClass}"
          .removeClass 'ui-state-ok'
          .find(".#{type}s-header-text")
            .text "#{count}
              #{@utils.pluralizeByNum @utils.capitalize(type), count}"
            .end()
          .find(".#{type}s-header-icon")
            .addClass 'fa-exclamation-triangle'
            .removeClass 'fa-check-circle'
      else
        $container.find(".#{type}s-header")
          .removeClass "ui-state-#{stateClass}"
          .addClass 'ui-state-ok'
          .find(".#{type}s-header-text")
            .text "No #{@utils.capitalize type}s"
            .end()
          .find(".#{type}s-header-icon")
            .removeClass 'fa-exclamation-triangle'
            .addClass 'fa-check-circle'

    hideGeneralWarningsAndErrors: ->
      @$('.general-errors-container').hide()
      @$('.general-warnings-container').hide()

    getWarningHTML: (warningsArray) ->
      warnings = ['<ul class="import-warnings-list">']
      for warning in warningsArray
        if warning.solution
          warnings.push "<li><div class='import-warning ui-state-highlight
            ui-corner-all'><i class='fa fa-fw fa-exclamation-triangle'
            ></i>#{warning.msg}<button class='solution-button'
            >#{warning.solution.name}</button></div></li>"
        else
          warnings.push "<li><div class='import-warning ui-state-highlight
            ui-corner-all'><i class='fa fa-fw fa-exclamation-triangle'
            ></i>#{warning.msg}</div></li>"
      warnings.push '</ul>'
      warnings.join '\n'

    getErrorHTML: (errorsArray) ->
      errors = ['<ul class="import-errors-list">']
      for error in errorsArray
        errors.push "<li><div class='import-error ui-state-error ui-corner-all'
          ><i class='fa fa-fw fa-exclamation-triangle'></i>#{error.msg}</div></li>"
      errors.push '</ul>'
      errors.join '\n'

    getNoErrorsHTML: -> "<i class='fa fa-fw fa-check-circle'></i>
      <span>No errors</span>"

    getNoWarningsHTML: -> "<i class='fa fa-fw fa-check-circle'></i>
      <span>No warnings</span>"

    # Create an object attribute that keys to objects which in turn map string
    # representations of relational values to the corresponding object
    # representations. E.g., objects that map things like 'Joel Dunham' to
    # `{first_name: 'Joel', ...}`, etc. These objects are used to "parse" user
    # input values for "elicitor", etc. in CSV import files.
    getStringToObjectMappers: ->
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

    # The user has clicked on the "Import" button of a CSV form row.
    importSingleCSVRow: (event) ->
      if _.isNumber event
        formIndex = event
      else
        formIndex = @getFormIndexFromViewClickEvent event
        if formIndex is null
          Backbone.trigger 'csvFormImportFail'
          return
      formObject = @getFormObjectFromCSVRowIndex formIndex
      if formObject is null
        Backbone.trigger 'csvFormImportFail'
        return

    importSelectedCSVRows: ->
      console.log 'you want to IMPORT all selected rows'
      # for row, index of csvRows
      #   @importSingleCSVRow index

    # The user has clicked on the "Validate" button of a CSV form row.
    validateSingleCSVRow: (event) ->
      if _.isNumber event
        formIndex = event
      else
        formIndex = @getFormIndexFromViewClickEvent event
        if formIndex is null
          Backbone.trigger 'csvFormValidateFail'
          return
      formObject = @getFormObjectFromCSVRowIndexAndFix formIndex
      if formObject is null
        Backbone.trigger 'csvFormValidateFail'
        return null
      @displayErrorsForRow formIndex
      @displayWarningsForRow formIndex
      formObject

    disableAllControls: ->
      console.log 'disabling all controls'
      @$('button').button 'disable'
      @$('select').selectmenu 'option', 'disabled', true

    enableAllControls: ->
      console.log 'enabling all controls'
      @$('button').button 'enable'
      @$('select').selectmenu 'option', 'disabled', false

    searchForFilenames: ->
      filenames = _.keys @filenames
      search =
        filter: ["or", [
          ["File", "filename", "in", filenames]
          ["File", "name", "in", filenames]]]
        order_by: ["File", "id", "desc"]
      paginator = {page:1, items_per_page: filenames.length}
      @dummyFileModel.search search, paginator

    fileSearchFail: (responseJSON) ->
      @validateSelectedCSVRowsFinal()

    fileSearchSuccess: (responseJSON) ->
      if responseJSON.paginator.count > 0
        files = responseJSON.items
        for index, formObject of @formObjects
          if formObject.files.length > 0
            newFilesArray = []
            for filename in formObject.files
              fileObject = _.findWhere files, filename: filename
              if not fileObject
                fileObject = _.findWhere files, name: filename
              if fileObject
                newFilesArray.push fileObject
              else
                warningObject =
                  msg: "Unable to find a file with (file)name “#{filename}”"
                  solution:
                    name: "Create file named #{filename}"
                    perform: do (filename) =>
                      -> @createResource filename, 'files'
                @addToWarnings index, warningObject
            formObject.files = newFilesArray
      @validateSelectedCSVRowsFinal()

    validateSelectedCSVRowsFinal: ->
      @displayGeneralWarnings()
      @displayGeneralErrors()
      @buttonify()
      @stopSpin()
      @enableAllControls()

    validateSelectedCSVRows: ->
      @spin()
      @disableAllControls()
      x = =>
        @$('.import-preview-table-body .import-preview-table-row')
          .each (index, row) =>
            if @$(row).find('.deselect-for-import').length > 0
              formObject = @validateSingleCSVRow index
              if formObject then @formObjects[index] = formObject
        if _.keys(@filenames).length > 0
          @searchForFilenames()
        else
          @validateSelectedCSVRowsFinal()

      # For some strange reason this negligible timeout is needed in order to
      # force the spinner to appear. Without it, it seems that jQuery puts it
      # into a queue of DOM manipulations that it performs in one go.
      setTimeout x, 50

    # The user has clicked on the "View" button of a CSV form row. So, we
    # attempt to display the to-be-imported form using a `FormViewForImport`
    # instance.
    viewSingleCSVRow: (event) ->
      formIndex = @getFormIndexFromViewClickEvent event
      if formIndex is null
        Backbone.trigger 'csvFormDisplayAsIGTFail'
        return
      selector = ".import-preview-table-row-display-container.\
        form-for-import-#{formIndex}"
      $displayContainer = @$(selector).first()
      if $displayContainer.is ':visible'
        $displayContainer.slideUp()
        @viewAsIGTButtonStateClosed formIndex
        return
      else
        $displayContainer.slideDown()
        @viewAsIGTButtonStateOpen formIndex
      if formIndex of @renderedFormViews then return
      formObject = @getFormObjectFromCSVRowIndexAndFix formIndex

      if formObject is null
        Backbone.trigger 'csvFormDisplayAsIGTFail'
        return null

      @displayErrorsForRow formIndex
      @displayWarningsForRow formIndex

      # Create the Dative-native instance and display it beneath the CSV row.
      formModel = new FormModel formObject, collection: @formsCollection
      formView = new FormViewForImport model: formModel
      formView.expanded = true
      formView.dataLabelsVisible = true
      formView.effectuateExpanded()
      $displayContainer.html formView.render().el
      @rendered formView
      @renderedFormViews[formIndex] = formView
      do (formIndex) =>
        @listenTo formView, "newFormView:hide",
          => @hideFormView formIndex

    # The user has clicked on the "X" button of a `FormViewForImport` instance
    # so we hide the enclosing <div>.
    hideFormView: (formIndex) ->
      if formIndex of @renderedFormViews
        selector = ".import-preview-table-row-display-container.\
          form-for-import-#{formIndex}"
        @$(selector).first().slideUp()

    closeRenderedFormViews: ->
      for index, formView of @renderedFormViews
        formView.close()
        @closed formView
      @renderedFormViews = {}

    viewSelectedCSVRows: ->
      console.log 'you want to VIEW all selected rows'

    # First get the index of the to-be-imported form, given the click event
    # from clicking that form's CSV row's "View" button.
    getFormIndexFromViewClickEvent: (event) ->
      try
        formIndex = Number(@$(event.currentTarget).data('index'))
      catch
        formIndex = null
      if _.isNaN formIndex then formIndex = null
      formIndex

    # Given the index of a form row within a CSV table, return the form as an
    # object while also fixing/validating it: i.e., by removing uneditable
    # attributes and fixing relational values. Note: the methods called in here
    # have side effects that will change the instance variable `@warnings`.
    getFormObjectFromCSVRowIndexAndFix: (formIndex) ->
      formObject = @getFormObjectFromCSVRowIndex formIndex
      formObject = @removeUneditableAttributes formObject, formIndex
      formObject = @fixDateElicited formObject
      formObject = @fixTranslations formObject
      formObject = @manyToOneStringToObject formObject, formIndex
      formObject = @manyToManyStringToArray formObject, formIndex
      formModel = new FormModel(formObject)
      errors = formModel.validate()
      if errors
        for attr, errorMsg of errors
          errorObject =
            msg: "#{attr}: #{errorMsg}"
            solution: @getErrorSolution errorMsg
          @addToErrors formIndex, errorObject
      formObject

    # Return an object that represents a solution to a warning or an error.
    # This object needs to have a string 'name' attribute and a 'perform'
    # method that is a function that performs the solution, usually the
    # creation of some related resource, e.g., a tag.
    getErrorSolution: (errorMsg) ->
      onsole.log "find a solution for #{errorMsg}"
      name: 'Fix it!'
      perform: ->

    # Given the index of a form row within a CSV table, return the form as an
    # object.
    getFormObjectFromCSVRowIndex: (formIndex) ->
      formArray = @importCSVArray[formIndex]
      if not formArray then return null
      columnLabels = @getColumnLabels()
      formObject = {}
      for value, index in formArray
        label = columnLabels[index]
        if label
          formObject[label] = value
      formObject

    # Remove the uneditable form attributes (e.g., id) from a (to-be-imported)
    # form object.
    removeUneditableAttributes: (formObject, formIndex) ->
      uneditableAttributes = []
      for attr of formObject
        if attr not in @dummyFormModel.editableAttributes
          delete formObject[attr]
          uneditableAttributes.push attr
      for attr in uneditableAttributes
        warningObject =
          msg: "Values in the “#{@utils.snake2regular attr}” column will
            not be imported."
          solution: null
        @addToWarnings 'general', warningObject
      formObject

    addToWarnings: (index, warning) ->
      if index of @warnings
        if not _.findWhere(@warnings[index], msg: warning.msg)
          @warnings[index].push warning
      else
        @warnings[index] = [warning]

    addToErrors: (index, error) ->
      if index of @errors
        if not _.findWhere(@errors[index], msg: error.msg)
          @errors[index].push error
      else
        @errors[index] = [error]

    # Convert translations-as-string to translations-as-array-of-objects.
    # Note: assumes that translations are delimited by a semicolon. This is
    # potentially a problematic assumption and should be user-configurable.
    # TODO: Dative NEEDS to request the web service's settings as soon as login
    # occurs; this is needed elsewhere, but here it's relevant for getting the
    # possible grammaticality values.
    fixTranslations: (formObject) ->
      grammaticalities = ['*', '?', '#']
      if 'translations' of formObject
        translationsString = formObject.translations
        translationsArray = (t.trim() for t in translationsString.split(';'))
        newTranslations = []
        for translationString in translationsArray
          if translationString.length > 1 and
          translationString[0] in grammaticalities
            newTranslations.push
              transcription: translationString[1...]
              grammaticality: translationString[0]
          else
            newTranslations.push
              transcription: translationString
              grammaticality: ''
        formObject.translations = newTranslations
      formObject

    # Convert user-supplied yyyy-mm-dd dates to dd/mm/yyyy format.
    fixDateElicited: (formObject) ->
      if formObject.date_elicited
        formObject.date_elicited =
          @utils.convertDateISO2mdySlash formObject.date_elicited
      formObject

    # Try to convert many-to-one string values to objects. Delete these values
    # if this is not possible.
    manyToOneStringToObject: (formObject, formIndex) ->
      for attr, val of formObject
        if val and attr in @dummyFormModel.manyToOneAttributes
          if attr of @stringToObjectMappers
            # For some reason, the pre-generated string reps of object values
            # are sometimes wrapped in double quotation marks (?!) ... hence
            # the odd predicate in the list comprehension below.
            matches = (p for p in @stringToObjectMappers[attr] \
              when p[0] in [val, "\"#{val}\""])
            if matches.length > 0
              formObject[attr] = matches[0][1]
            else
              warningObject =
                msg: "Unable to use “#{val}” as a value for the many-to-one
                  attribute #{attr}"
                solution:
                  name: "Create #{val}"
                  perform: do (val, attr) =>
                    -> @createResource val, attr
              @addToWarnings formIndex, warningObject
              delete formObject[attr]
          else
            warningObject =
              msg: "Unable to use “#{val}” as a value for the many-to-one
                attribute #{attr}"
              solution:
                name: "Create #{val}"
                perform: do (val, attr) =>
                  -> @createResource val, attr
            @addToWarnings formIndex, warningObject
            delete formObject[attr]
      formObject

    createResource: (val, attr) ->
      console.log "You want to create a resource for the form attribute #{attr}
        using the string value #{val}"

    # Try to convert many-to-many string values to arrays of objects. Delete
    # these values if this is not possible.
    manyToManyStringToArray: (formObject, formIndex) ->
      for attr, val of formObject
        if val and attr in @dummyFormModel.manyToManyAttributes
          if attr is 'tags'
            formObject = @parseTagsString formObject, attr, val, formIndex
          else if attr is 'files'
            formObject = @parseFilesString formObject, attr, val, formIndex
          else
            warningObject =
              msg: "Unable to use “#{val}” as a value for the many-to-many
                attribute #{attr}"
              solution:
                name: "Create #{val}"
                perform: do (val, attr) =>
                  -> @createResource val, attr
            @addToWarnings formIndex, warningObject
            delete formObject[attr]
      formObject

    # Parse a string representation of an array of tags-as-objects. Assume that
    # commas delimit tags and require that tags exist as a resource in the
    # system already.
    parseTagsString: (formObject, attr, val, formIndex) ->
      attrArray = (e.trim() for e in val.split ',')
      tagsForFormToBeImported = []
      unrecognizedTags = []
      existingTags = globals.get('tags').data
      for tagName in attrArray
        tagObject = _.findWhere existingTags, {name: tagName}
        if tagObject
          tagsForFormToBeImported.push tagObject
        else
          unrecognizedTags.push tagName
      if tagsForFormToBeImported.length > 0
        formObject.tags = tagsForFormToBeImported
      else
        warningObject =
          msg: "Unable to use “#{val}” as a value for the many-to-many
            attribute #{attr}"
          solution:
            name: "Create #{val}"
            perform: do (val, attr) =>
              -> @createResource val, attr
        @addToWarnings formIndex, warningObject
        delete formObject.tags
      for tag in unrecognizedTags
        warningObject =
          msg: "Unable to recognize the tag “#{tag}” in “#{val}”."
          solution:
            name: "Create #{val}"
            perform: do (val, attr) =>
              -> @createResource val, attr
        @addToWarnings formIndex, warningObject
      formObject

    # Parse a string representation of for a CSV row's `files` column. Assume
    # it is a comma-delimited list of filenames. Save the filenames for later
    # processing.
    # FOX
    parseFilesString: (formObject, attr, val, formIndex) ->
      filenameArray = (fn.trim() for fn in val.split ',')
      formObject.files = filenameArray
      for fn in filenameArray
        @filenames[fn] = null
      formObject

    # Return an object that maps column indices to the user-selected form field
    # labels, e.g., {n: 'transcription'} indicates that the nth row contains
    # transcription values.
    getColumnLabels: ->
      labels = {}
      @$('select.column-header').each (index, element) =>
        $element = @$ element
        label = $element.val()
        columnIndex = $element.attr('name').split('_')[1]
        labels[columnIndex] = label
      labels

    # Update the state of all of the buttons that operate over all selected CSV
    # rows, i.e, "Import All", "View All" and "Validate All". The "Import"
    # button indicates how many form rows are selected for import; we disable the
    # buttons if no rows are selected.
    allSelectedButtonsState: ->
      selectedCount = @$('i.deselect-for-import').length
      totalCount = @importCSVArray.length
      @$('.import-selected-button-text').text "Import Selected (#{selectedCount} of
        #{totalCount})"
      if selectedCount is 0
        @$('button.import-selected-button').button 'disable'
        @$('button.view-selected-button').button 'disable'
        @$('button.validate-selected-button').button 'disable'
      else
        @$('button.import-selected-button').button 'enable'
        @$('button.view-selected-button').button 'enable'
        @$('button.validate-selected-button').button 'enable'

    selectAllFormsForImport: ->
      @$('i.select-for-import')
        .removeClass 'fa-square select-for-import'
        .addClass 'fa-check-square deselect-for-import'
      @allSelectedButtonsState()

    deselectAllFormsForImport: ->
      @$('i.deselect-for-import')
        .addClass 'fa-square select-for-import'
        .removeClass 'fa-check-square deselect-for-import'
      @allSelectedButtonsState()

    # <Return> and <SpaceBar> on a focused row toggle that row's selected-ness.
    keydownSelectFormForImport: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @selectFormForImport event

    keydownDeselectFormForImport: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @deselectFormForImport event

    # A selected form has a checkbox icon.
    selectFormForImport: (event) ->
      @$(event.currentTarget).first()
        .removeClass 'fa-square select-for-import'
        .addClass 'fa-check-square deselect-for-import'
        .focus()
      @allSelectedButtonsState()

    # A de-selected form has an empty box icon.
    deselectFormForImport: (event) ->
      @$(event.currentTarget).first()
        .removeClass 'fa-check-square deselect-for-import'
        .addClass 'fa-square select-for-import'
        .focus()
      @allSelectedButtonsState()

    # Programmatically click the hidden button that open's the browser's "find
    # file" dialog.
    clickFileUploadInput: ->
      #<i class='import-spinner fa fa-fw fa-circle-o-notch fa-spin'></i>
      @$('[name=file-upload-input]').click()

    render: ->
      @hasBeenRendered = true
      @$el.append @template(importTypes: @importTypes)
      @$target = @$ '.dative-importer-target'
      @guify()
      @progressBarify()
      @$('div.dative-importer-preview').hide()
      @$('button.discard-file-button').hide()
      @$('div.import-preview-table-wrapper')
        .css("border-color", @constructor.jQueryUIColors().defBo)
      @

    tooltipify: ->
      @$('.dative-tooltip').tooltip position: @tooltipPositionLeft()

    defaultPosition: ->
      my: "center"
      at: "center"
      of: @$target.first().parent().parent()

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

    # TODO: is this even being used?
    progressBarify: ->
      @$('.file-upload-container').hide()
      @$('.file-upload-progress-bar').first().progressbar()

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {left: '-35%'}

    spin: ->
      @$('.spinner-container').first().spin @spinnerOptions()

    stopSpin: ->
      @$('.spinner-container').first().spin false

    # We only allow CSV imports right now.
    importTypes:
      csv:
        mimeTypes: ['text/csv']
        label: 'CSV'

    # Handle the user selecting a file from their file system. In the
    # successful cases, this will result in the file being parsed as CSV and
    # then displayed in a table.
    # Note: the attributes of the `fileBLOB` object are `name`, `type`, `size`,
    # `lastModified` (timestamp), and `lastModifiedDate` (`Date` instance).
    handleFileSelect: (event) ->
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
          @spin()
          do (reader) =>
            x = => reader.readAsText @fileBLOB
            setTimeout x, 50
      else
        Backbone.trigger 'fileSelectError'

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
      @warnings = {}
      @errors = {}
      @filenames = {}
      @formObjects = {}
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
        @importCSVArray = @parseCSV fileData
        @$('.discard-file-button').show()
        @displayCSVImportAsTable()
        @displayFileMetadata()
        @stopSpin()
      catch
        Backbone.trigger 'importError'
        @stopSpin()

    # Return an object that maps CSV line indices to the names of the
    # corresponding (OLD) form attributes. This works only if the CSV file
    # contains a header line (i.e., line 1) that contains names that match OLD
    # form attribute names, e.g., "transcription", "translations", etc.
    mapCSVColumnsToFormAttributes: ->
      formAttributes = FormModel::defaults()
      headerMap = {}
      @firstLineIsHeader = true
      for headerValue, index in @importCSVArray[0]
        if headerValue of formAttributes
          headerMap[index] = headerValue
        else if headerValue.toLowerCase() of formAttributes
          headerMap[index] = headerValue.toLowerCase()
        else if @utils.regular2snake(headerValue) of formAttributes
          headerMap[index] = @utils.regular2snake headerValue
        else
          headerMap[index] = null
          # If any column header is unrecognizable, we categorize the import
          # file has not having a header line. We still use any headers we may
          # have gleaned though.
          @firstLineIsHeader = false
      if @firstLineIsHeader then @importCSVArray = @importCSVArray[1...]
      [headerMap, formAttributes]

    # Return a <select> that contains all of the possible attributes of a(n
    # OLD) form resource. The user will use this to choose where the values in
    # a specific column should go.
    getFormAttributesSelect: (formAttributes, columnName, index) ->
      select = ["<select
        class='column-header dative-tooltip'
        name='column_#{index}'
        title='Choose the form field label that the values in this column
               belong to'
               ><option value=''>Please select a form field label.</option>"]
      # Get case-insensitive sorted form attributes as array.
      formAttributes = _.keys(formAttributes)
        .sort (a, b) -> a.toLowerCase().localeCompare(b.toLowerCase())
      for formAttribute in formAttributes
        if formAttribute is columnName
          select.push "<option value='#{formAttribute}' selected
            >#{@utils.snake2regular formAttribute}</option>"
        else
          select.push "<option value='#{formAttribute}'
            >#{@utils.snake2regular formAttribute}</option>"
      select.push '</select>'
      select.join '\n'

    # HTML for the "Select All" button.
    selectAllButton: -> "<button class='select-all-for-import ui-corner-all'
      >Select All</button>"

    # HTML for the "De-select All" button.
    selectNoneButton: -> "<button class='select-none-for-import ui-corner-all'
      >De-select All</button>"

    # HTML for the "De-select" checkbox.
    deselectCheckbox: (index) -> "<i class='fa fa-2x fa-check-square
      deselect-for-import ui-corner-all' tabindex='0'></i>"

    # "Import" button for a single CSV row.
    importButton: (index) -> "<button class='import-csv-row dative-tooltip
      import-preview-row-button'
      data-index='#{index}' title='Import just this form'>Import</button>"

    # "View" (as IGT `FormViewForImport`) button.
    viewAsIGTButton: (index) -> "<button class='view-csv-row dative-tooltip
      import-preview-row-button'
      data-index='#{index}' title='View this form in IGT format'>View</button>"

    # "Validate" button for a single CSV row.
    validateButton: (index) -> "<button class='validate-csv-row dative-tooltip
      import-preview-row-button'
      data-index='#{index}' title='Check for potential warnings and errors
      prior to importing this row'>Validate</button>"

    viewAsIGTButtonStateClosed: (formIndex) ->
      @$(".form-for-import-#{formIndex} button.view-csv-row")
        .button label: 'View'
        .tooltip content: 'View this form in IGT format'

    viewAsIGTButtonStateOpen: (formIndex) ->
      @$(".form-for-import-#{formIndex} button.view-csv-row")
        .button label: 'Hide'
        .tooltip content: 'Hide the IGT-formatted display of this form'

    # Display the imported CSV file in a big table (made up of <div> elements).
    displayCSVImportAsTable: ->
      [headerMap, formAttributes] =
        @mapCSVColumnsToFormAttributes @importCSVArray
      @displayCSVTableHeader headerMap, formAttributes
      @displayCSVTableBody()
      @$('.import-preview-table-cell, .import-preview-table-row')
        .css("border-color", @constructor.jQueryUIColors().defBo)
      @buttonify()
      @tooltipify()
      @columnHeaderChanged()
      @allSelectedButtonsState()

    # Display the header row of the CSV table in the DOM. Param `headerMap`
    # maps column indices to column labels. Param `formAttributes` is an object
    # whose keys are form attributes names, i.e., field labels.
    displayCSVTableHeader: (headerMap, formAttributes) ->
      headerRow = ["<div class='import-preview-table-row'>
        <div class='import-preview-table-header-cell
                    import-preview-controls-cell'
        >#{@selectAllButton()}#{@selectNoneButton()}</div>"]
      for value, index in @importCSVArray[0]
        columnName = headerMap[index]
        selectElement =
          @getFormAttributesSelect formAttributes, columnName, index
        columnAlert = @getColumnAlert index, columnName
        headerRow.push "<div class='import-preview-table-header-cell'
          >#{selectElement}#{columnAlert}</div>"
      headerRow.push "</div>"
      @$('.dative-importer-preview div.import-preview-table').first()
        .find 'div.import-preview-table-head'
        .html headerRow.join('\n')
      @selectmenuify 'select.column-header'

    # Display the body rows of the CSV table in the DOM.
    displayCSVTableBody: ->
      body = []
      for line, rowIndex in @importCSVArray
        body.push "<div tabindex='0'
          class='import-preview-table-row form-for-import-#{rowIndex}'
          ><div class='form-for-import-select-cell import-preview-table-cell
            cell-0'
          >#{@deselectCheckbox()}
           #{@importButton rowIndex}
           #{@viewAsIGTButton rowIndex}
           #{@validateButton rowIndex}</div>"
        for value, colIndex in line
          body.push "<div class='import-preview-table-cell
            cell-#{colIndex + 1}' contenteditable='true'>#{value}</div>"
        body.push "</div>
          <div class='import-preview-table-row-errors-container
            form-for-import-#{rowIndex} errors-container invisible'>
              <h1 class='errors-header ui-state-error ui-corner-all'
                  ><i class='errors-header-icon fa fa-fw
                  fa-exclamation-triangle'></i
                  ><span class='errors-header-text'>Errors</span></h1>
              <div class='errors-inner-container'></div>
            </div>
          <div class='import-preview-table-row-warnings-container
            form-for-import-#{rowIndex} warnings-container invisible'>
              <h1 class='warnings-header ui-state-highlight ui-corner-all'
                  ><i class='warnings-header-icon fa fa-fw
                  fa-exclamation-triangle'></i
                  ><span class='warnings-header-text'>Warnings</span></h1>
              <div class='warnings-inner-container'></div>
            </div>
          <div class='import-preview-table-row-display-container invisible
            form-for-import-#{rowIndex}'></div>"
      @$('.dative-importer-preview').show()
      @$('.dative-importer-preview div.import-preview-table').first()
        .find 'div.import-preview-table-body'
        .html body.join('\n')

    # Return HTML for an <i> tag that alerts the user about warnings and errors
    # wrt their chosen column header.
    getColumnAlert: (index, columnName) ->
      class_ = "class='column-alert column-#{index} ui-corner-all fa fa-fw
                fa-exclamation-triangle ui-state-highlight invisible
                dative-tooltip'"
      if columnName
        "<i #{class_} title='Values in this column will not be imported because
          users cannot specify “#{@utils.snake2regular columnName}” values;
          they can only be specified by the system.'></i>"
      else
        "<i #{class_} title='Values in this column will not be imported; please
          choose a form field label for this column.'></i>"

    # The user-specified value in a column header select box has changed: based
    # on this, we activate/deactivate the column and alter its width.
    columnHeaderChanged: ->
      @setColumnActivities()
      @setColumnWidths()

    # Set the columns widths of the "table" (made up of <div>s), based on the
    # widths of the header cells. This is called whenever a selectmenu option
    # is changed in a header cell.
    setColumnWidths: ->
      $divTable = @$ 'div.import-preview-table'
      widths = {}
      $divTable.find('div.import-preview-table-row:first').children().each(
        (index, element) =>
          width = @$(element)[0].getBoundingClientRect().width - 11
          widths[index] = width
      )
      for index, width of widths
        $divTable.find("div.import-preview-table-cell.cell-#{index}").css
            'min-width': "#{width}px"
            'max-width': "#{width}px"

    # Enable/disable the column based on its user-specified label. If the label
    # corresponds to a non-editable form attribute, e.g., `modifier` or `id`,
    # then we change the display the column to indicate that it is "disabled",
    # i.e., that it won't be included in the import.
    setColumnActivities: ->
      columnLabels = @getColumnLabels()
      for index, columnLabel of columnLabels
        index = Number index
        @$("i.column-alert.column-#{index}").tooltip
          content: "Values in this column will not be imported because
            users cannot specify “#{@utils.snake2regular columnLabel}”
            values; they can only be specified by the system."
        if columnLabel in @dummyFormModel.editableAttributes
          @$("div.import-preview-table-cell.cell-#{index + 1}")
            .removeClass 'ui-state-disabled'
          @$("i.column-alert.column-#{index}").hide()
        else
          @$("div.import-preview-table-cell.cell-#{index + 1}")
            .addClass 'ui-state-disabled'
          @$("i.column-alert.column-#{index}").show()

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

    # WARNING: DEPRECATED. Using `parseCSV` above instead.
    # Parse a CSV string into an array of arrays. The default delimiter
    # is the comma, but this be overriden in the `stringDelimiter` argument.
    # See http://stackoverflow.com/a/1293163
    csv2array: (stringData, stringDelimiter) ->

      # Check to see if the delimiter is defined. If not, then default to comma.
      stringDelimiter = stringDelimiter or ','

      # Create a regular expression to parse the CSV values.
      regexString = "(\\#{stringDelimiter}|\\r?\\n|\\r|^)\
        (?:\"([^\"]*(?:\"\"[^\"]*)*)\"|\
        ([^\"\\#{stringDelimiter}\\r\\n]*))"
      regexPattern = new RegExp regexString, "gi"

      # Create an array to hold our data. Give the array a default empty first
      # row.
      arrayData = [[]]

      # Create an array to hold our individual pattern matching groups.
      arrayMatches = null

      # Keep looping over the regular expression matches until we can no longer
      # find a match.
      while (arrayMatches = regexPattern.exec(stringData))

        # Get the delimiter that was found.
        stringMatchedDelimiter = arrayMatches[1]

        # Check to see if the given delimiter has a length (is not the start of
        # string) and if it matches field delimiter. If it does not, then we
        # know that this delimiter is a row delimiter.
        if stringMatchedDelimiter.length and
        stringMatchedDelimiter isnt stringDelimiter
          # Since we have reached a new row of data, add an empty row to our
          # data array.
          arrayData.push []

        # Now that we have our delimiter out of the way, let's check to see
        # which kind of value we captured (quoted or unquoted).
        if arrayMatches[2]
          # We found a quoted value. When we capture this value, unescape any
          # double quotes.
          regex = new RegExp "\"\"", "g"
          stringMatchedValue = arrayMatches[2].replace(regex, '"')
        else
          # We found a non-quoted value.
          stringMatchedValue = arrayMatches[3]

        # Now that we have our value string, let's add it to the data array.
        arrayData[arrayData.length - 1].push stringMatchedValue

      # Return the parsed data.
      arrayData
      lineLength = arrayData[0].length
      (l for l in arrayData when l.length is lineLength)


