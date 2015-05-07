define [
  './resource'
  './form-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './judgement-value-field-display'
  './morpheme-break-field-display'
  './morpheme-gloss-field-display'
  './phonetic-transcription-field-display'
  './grammaticality-value-field-display'
  './translations-field-display'
  './source-field-display'
  './array-of-objects-with-title-field-display'
  './comments-field-display'
  './modified-by-user-field-display'
  './../models/form'
  './../utils/globals'
], (ResourceView, FormAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, JudgementValueFieldDisplayView,
  MorphemeBreakFieldDisplayView, MorphemeGlossFieldDisplayView,
  PhoneticTranscriptionFieldDisplayView, GrammaticalityValueFieldDisplayView,
  TranslationsFieldDisplayView, SourceFieldDisplayView,
  ArrayOfObjectsWithTitleFieldDisplayView, CommentsFieldDisplayView,
  ModifiedByUserFieldDisplayView, FormModel, globals) ->

  # Form Base View
  # --------------
  #
  # A base class for displaying individual forms and form-like objects, viz.
  # previous versions of forms.

  class FormBaseView extends ResourceView

    className: 'dative-resource-widget dative-form-object dative-paginated-item
      dative-widget-center ui-corner-all'

    initialize: (options) ->
      super
      @setAttribute2DisplayView()
      @setAttributeClasses()

    setAttributeClasses: ->
      @setPrimaryAttributes()
      @setSecondaryAttributes()

    setPrimaryAttributes: ->
      igtAttributes = @getFormAttributes @activeServerType, 'igt'
      translationAttributes =
        @getFormAttributes @activeServerType, 'translation'
      @primaryAttributes = igtAttributes.concat translationAttributes

    setSecondaryAttributes: ->
      secondaryAttributes = @getFormAttributes @activeServerType, 'secondary'
      if @activeServerType is 'FieldDB'
        # In the FieldDB case, we want to display all datum fields, even if
        # they're not listed in the secondary attributes array of the
        # application settings model.
        datumFields = (x.label for x in @model.get('datumFields'))
        grammaticalityAttributes =
          @getFormAttributes @activeServerType, 'grammaticality'
        accountedForAttributes = grammaticalityAttributes.concat(
          secondaryAttributes, @primaryAttributes)
        for field in datumFields
          if field not in accountedForAttributes
            secondaryAttributes.push field
      @secondaryAttributes = secondaryAttributes

    setAttribute2DisplayView: ->
      switch @activeServerType
        when 'FieldDB'
          @attribute2displayView = @attribute2displayViewFieldDB
        when 'OLD'
          @attribute2displayView = @attribute2displayViewOLD

    resourceName: 'form'

    resourceAddWidgetView: FormAddWidgetView

    attribute2displayView: {}

    attribute2displayViewFieldDB:
      utterance: JudgementValueFieldDisplayView
      morphemes: MorphemeBreakFieldDisplayView
      gloss: MorphemeGlossFieldDisplayView
      dateElicited: DateFieldDisplayView
      dateEntered: DateFieldDisplayView
      dateModified: DateFieldDisplayView
      comments: CommentsFieldDisplayView
      modifiedByUser: ModifiedByUserFieldDisplayView

    attribute2displayViewOLD:
      narrow_phonetic_transcription: PhoneticTranscriptionFieldDisplayView
      phonetic_transcription: PhoneticTranscriptionFieldDisplayView
      transcription: GrammaticalityValueFieldDisplayView
      translations: TranslationsFieldDisplayView
      morpheme_break: MorphemeBreakFieldDisplayView
      morpheme_gloss: MorphemeGlossFieldDisplayView
      syntactic_category: ObjectWithNameFieldDisplayView
      elicitation_method: ObjectWithNameFieldDisplayView
      source: SourceFieldDisplayView
      date_elicited: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      speaker: PersonFieldDisplayView
      elicitor: PersonFieldDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      verifier: PersonFieldDisplayView
      collections: ArrayOfObjectsWithTitleFieldDisplayView
      tags: ArrayOfObjectsWithNameFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

    # Get an array of form attributes (form app settings model) for the
    # specified server type and category (e.g., 'igt' or 'secondary').
    getFormAttributes: (serverType, category) ->
      switch serverType
        when 'FieldDB' then attribute = 'fieldDBFormCategories'
        when 'OLD' then attribute = 'oldFormCategories'
      try
        globals.applicationSettings.get(attribute)[category]
      catch
        console.log "WARNING: could not get an attributes array for
          #{serverType} and #{category}"
        []

    # Highlight any differences between this view's model and its comparator
    # model, if there is one.
    diffThis: ->
      if @comparatorModel
        for attribute, value of @model.attributes
          @displayViews = @primaryDisplayViews.concat @secondaryDisplayViews
          if attribute not in ['id', 'datetime_modified'] and
          not _.isEqual(@comparatorModel.get(attribute), value)
            for displayView in @displayViews
              if attribute in displayView.governedAttributes()
                displayView.representationView.$el.addClass 'ui-state-error diffed'

    # Un-highlight any differences between this view's model and its comparator
    # model that may have been previously highlighted.
    undiffThis: ->
      @displayViews = @primaryDisplayViews.concat @secondaryDisplayViews
      for displayView in @displayViews
        displayView.representationView.$el.removeClass 'ui-state-error diffed'


    ############################################################################
    # IGT Intelinear Display Logic.
    ############################################################################

    # The `ResourceView` base class calls this at the end of
    # `renderDisplayViews`.
    renderDisplayViewsPost: -> @interlinearize()

    # Transform the display of the form IGT attributes into an interlinear,
    # columnarly aligned display. This is done by creating a <table> for each
    # multi-field line in the IGT display.
    interlinearize: ->

      # Params
      @igtWordBuffer = 60 # How many pixels between IGT word columns.
      @igtRowStepIndent = 50 # How many pixels to indent each subsequent IGT row.
      @igtMaxIndentations = 5 # When we stop indenting IGT rows.
      @igtRowVerticalSpacer = 10 # How many pixels of vertical space between IGT rows.

      # Get info about IGT data (`igtMap`) and the longest word count (`wordCount`)
      [igtMap, wordCount] = @getIGTWords()

      # If we only have one word, then there is no point in creating an
      # interlinear display.
      if wordCount < 2 then return

      # Wrap the IGT words in <div> tags so we can get their widths.
      igtMap = @wrapIGTWords igtMap, wordCount

      # We need to wait a millisecond for the wrapped word widths to not be 0.
      setTimeout (=> @_interlinearize igtMap), 1

    # Return an object with information about each IGT field: most importantly
    # the array of words that comprise its value; also return the word count of
    # the field with the most words in it.
    getIGTWords: ->
      igtMap = {}
      wordCount = 0
      for attribute in @getFormAttributes @activeServerType, 'igt'
        className = @utils.snake2hyphen attribute # WARN: OLD-specific
        selector = ".dative-field-display >
          .dative-field-display-representation-container > .#{className}"
        $element = @$(selector).first()
        $element.css 'white-space', 'nowrap'
        value = $element.text()
        words = value.split /\s+/
        if words.length > wordCount then wordCount = words.length
        igtMap[attribute] =
          className: className
          selector: selector
          value: value
          words: words
      [igtMap, wordCount]

    # Wrap each word of each IGT field in a <div> so that we can later query
    # the widths of these divs in order to determine where to place the words
    # in the final IGT HTML tables. Store the original HTML so we can restore
    # it later, if necessary.
    wrapIGTWords: (igtMap, wordCount) ->
      for attribute, vector of igtMap
        while vector.words.length < wordCount
          vector.words.push ''
        wrappedValue =
          ("<div class='igt-word'>#{w}</div>" for w in vector.words)
        wrappedValue = wrappedValue.join ''
        $igtLine = @$(vector.selector).first()
        vector.originalValue = $igtLine.html()
        $igtLine.html wrappedValue
      igtMap

    # Unwrap the words that we had previously wrapped.
    unwrapIGTWords: (igtMap) ->
      for attribute, vector of igtMap
        @$(vector.selector)
          .first().html vector.originalValue
          .css 'white-space', 'normal'

    # A continuation of the `interlinearize` method meant to be called after a
    # 1 second delay; this seems to be necessary because otherwise all of the
    # jQuery `.width()` calls will return 0.
    # TODO: RESEARCH: isn't there a jQuery `complete:` callback to handle this?
    _interlinearize: (igtMap) ->
      # Remove any information about IGT fields that are hidden.
      igtMap = @removeEmptyIGTLines igtMap

      # If there is only one IGT field with a value, then we should also
      # break from interlinearizing.
      # TODO: we should also remove the <div>-wrapping performed above.
      if _.keys(igtMap).length < 2
        @unwrapIGTWords igtMap
        return

      # Get an object that maps word indices the longes word (cell) with that
      # index.
      wordWidths = @getIGTWordWidths igtMap

      tablesData = @getIGTTablesData wordWidths
      @displayIGTTables tablesData, igtMap, wordWidths
      @hideIGTFields igtMap

    # If an IGT field is not displayed prior to interlinearization (because
    # it's empty), then it shouldn't be displayed by the `interlinearize`
    # method either.
    removeEmptyIGTLines: (igtMap) ->
      newIGTMap = {}
      for attribute, vector of igtMap
        $element = @$(vector.selector).first()
        if $element.is(':visible')
          newIGTMap[attribute] = vector
      newIGTMap

    # Return the data needed to create the set of IGT tables. This is an array
    # of index-containing arrays. Each array of indices represents the words
    # that will be present in that table.
    getIGTTablesData: (wordWidths) ->
      maxWidth = @$('.resource-primary-data').first().width()
      tablesData = []
      rowWidth = 0
      row = []
      lastIndex = _.keys(wordWidths).length - 1
      for index, wordWidth of wordWidths
        index = Number index
        rowWidth += wordWidth
        row.push index
        if rowWidth > maxWidth and row.length > 1
          rowWidth = wordWidth
          row.pop()
          tablesData.push row[...]
          row = [index]
        if index is lastIndex
          tablesData.push row
      tablesData

    # Get the width that each word will take up in the final IGT table. This is
    # the width of the longest word with index n, plus the word buffer.
    # The return object has word indices as keys and word widths as values.
    getIGTWordWidths: (igtMap) ->
      wordWidths = {}
      for attribute, vector of igtMap
        # It's crucial to return the previous IGT field displays to their
        # word-wrapping state so that `maxWidth` computed later on is accurate.
        @$(vector.selector).css 'white-space', 'normal'
        @$("#{vector.selector} div.igt-word").each (index, element) =>
          $element = @$ element
          elementWidth = $element.width()
          width = elementWidth + @igtWordBuffer
          if index of wordWidths
            if wordWidths[index] < width then wordWidths[index] = width
          else
            wordWidths[index] = width
      wordWidths

    # Write the IGT data to the DOM as a series of IGT tables. There is one
    # table for each line of IGT, i.e., one table for each columnarly aligned
    # group of words.
    displayIGTTables: (tablesData, igtMap, wordWidths) ->
      $tablesContainer = $ '<div>'
      for tableData, index in tablesData
        if index < @igtMaxIndentations
          leftIndent = index * @igtRowStepIndent
        else
          leftIndent = @igtMaxIndentations * @igtRowStepIndent
        $table = $ "<table class='igt-table' style='margin-bottom:
          #{@igtRowVerticalSpacer }px;'>"
        for attribute, vector of igtMap
          $row = $ '<tr>'
          for index, cellIndex in tableData
            word = vector.words[index]
            width = wordWidths[index]
            padding = ''
            if cellIndex is 0 then padding = "padding-left: #{leftIndent}px;'"
            style = "style='width: #{width}px;
                            min-width: #{width}px;
                            max-width: #{width}px;
                            #{padding}'"
            $row.append $("<td class='igt-word-cell' #{style}>#{word}</td>")
          $table.append $row
        $tablesContainer.append $table
      @$('.resource-primary-data').first().prepend $tablesContainer

    # Hide the previous displays for the IGT fields.
    hideIGTFields: (igtMap) ->
      # TODO: we should actually just tell the relevant IGT views to hide
      # themselves; however, this requires keeping an attribute-based dict to
      # them in the form superview, which we currently don't do ...
      igtClasses = (".dative-field-display-representation-container >
        .#{v.className}" for v in _.values igtMap).join ', '
      @$('.dative-field-display').each (index, element) =>
        $element = @$ element
        if $element.has(igtClasses).length then $element.hide()

