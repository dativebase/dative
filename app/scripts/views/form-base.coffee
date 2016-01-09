define [
  './resource'
  './file'
  './elicitation-method'
  './syntactic-category'
  './form-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './array-of-related-tags-field-display'
  './array-of-related-files-field-display'
  './judgement-value-field-display'
  './morpheme-break-field-display'
  './morpheme-gloss-field-display'
  './phonetic-transcription-field-display'
  './grammaticality-value-field-display'
  './translations-field-display'
  './source-field-display'
  './speaker-field-display'
  './array-of-objects-with-title-field-display'
  './comments-field-display'
  './modified-by-user-field-display'
  './field-display'
  './related-resource-field-display'
  './related-user-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './../models/form'
  './../models/file'
  './../models/elicitation-method'
  './../models/syntactic-category'
  './../collections/forms'
  './../collections/syntactic-categories'
  './../collections/elicitation-methods'
  './../utils/globals'
], (ResourceView, FileView, ElicitationMethodView, SyntacticCategoryView,
  FormAddWidgetView, PersonFieldDisplayView, DateFieldDisplayView,
  ObjectWithNameFieldDisplayView, ArrayOfObjectsWithNameFieldDisplayView,
  ArrayOfRelatedTagsFieldDisplayView, ArrayOfRelatedFilesFieldDisplayView,
  JudgementValueFieldDisplayView, MorphemeBreakFieldDisplayView,
  MorphemeGlossFieldDisplayView, PhoneticTranscriptionFieldDisplayView,
  GrammaticalityValueFieldDisplayView, TranslationsFieldDisplayView,
  SourceFieldDisplayView, SpeakerFieldDisplayView,
  ArrayOfObjectsWithTitleFieldDisplayView, CommentsFieldDisplayView,
  ModifiedByUserFieldDisplayView, FieldDisplayView,
  RelatedResourceFieldDisplayView, RelatedUserFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView, FormModel, FileModel,
  ElicitationMethodModel, SyntacticCategoryModel, FormsCollection,
  SyntacticCategoriesCollection, ElicitationMethodsCollection, globals) ->


  class VerifierFieldDisplayView extends RelatedUserFieldDisplayView

    attributeName: 'verifier'


  class ElicitorFieldDisplayView extends RelatedUserFieldDisplayView

    attributeName: 'elicitor'


  class SyntacticCategoryFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'syntacticCategory'
    attributeName: 'syntactic_category'
    resourceModelClass: SyntacticCategoryModel
    resourcesCollectionClass: SyntacticCategoriesCollection
    resourceViewClass: SyntacticCategoryView

    __resourceAsString__: (resource) ->
      try
        resource.name
      catch
        ''


  class ElicitationMethodFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'elicitationMethod'
    attributeName: 'elicitation_method'
    resourceModelClass: ElicitationMethodModel
    resourcesCollectionClass: ElicitationMethodsCollection
    resourceViewClass: ElicitationMethodView

    __resourceAsString__: (resource) ->
      try
        resource.name
      catch
        ''


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
      @events['click .morpheme-link'] = 'morphemeLinkClicked'

    listenToEvents: ->
      super
      @listenTo Backbone, 'fieldVisibilityChange', @fieldVisibilityChange

    # Return the object of arrays that categorize the fields of a forms
    # resource, e.g., into IGT fields, visible fields, etc.
    getFieldCategories: ->
      try
        globals.applicationSettings.get('resources')
          .forms.fieldsMeta[@activeServerType]
      catch
        {}

    fieldVisibilityChange: (resource, fieldName, visibilityValue) ->
      fieldCategories = @getFieldCategories()
      igtFields = fieldCategories.igt or []
      if resource is 'forms' and fieldName in igtFields
        @listenToOnce @model, 'fieldVisibilityChanged', @igtFieldVisibilityChanged

    igtFieldVisibilityChanged: -> @interlinearize true

    # A user has clicked on a morpheme link so we cause that morpheme (or those
    # morphemes) to be displayed using one or more FormViews in one or more
    # dialogs.
    morphemeLinkClicked: (event) ->
      @stopEvent event
      try
        id = (parseInt(x) for x in @$(event.target).attr('data-id').split(','))
      catch
        try
          $anchor = @$(event.target).closest 'a.morpheme-link'
          id = (parseInt(x) for x in $anchor.attr('data-id').split(','))
        catch
          console.log 'ERROR: unable to get id for morpheme clicked'
          return

      morphemesCollection = new FormsCollection()
      @morphemeModel = new FormModel({}, {collection: morphemesCollection})

      if id.length is 1
        @listenToOnce @morphemeModel, "fetchFormSuccess", @fetchMorphemeSuccess
        @morphemeModel.fetchResource id
      else # we search across forms for the ids
        paginator =
          page: 1
          items_per_page: 100
        query =
          filter: ["Form", "id", "in", id]
          order_by: ["Form", "id", "asc"]
        @listenToOnce @morphemeModel, 'searchSuccess', @searchSuccess
        @morphemeModel.search query, paginator

    # The morpheme's form model has been fetched from the server so we request
    # that it be displayed in a dialog box.
    fetchMorphemeSuccess: (formObject) ->
      @morphemeModel.set formObject
      Backbone.trigger 'showResourceModelInDialog', @morphemeModel, 'form'

    # The morphemes' form models have been fetched from the server so we
    # request that they be displayed in dialog boxes.
    searchSuccess: (responseJSON) ->
      morphemesCollection = new FormsCollection()
      # TODO: we can only display the first four matches because we only have 4
      # resource displayer dialogs. This should be fixed by allowing for the
      # display of multiple `ResourceView` instances in a single dialog box.
      for formObject in responseJSON.items[...4]
        model = new FormModel(formObject, {collection: morphemesCollection})
        Backbone.trigger 'showResourceModelInDialog', model, 'form'

    render: ->
      super
      # Every second we check if we should refresh the interlinear display.
      @lastKeydown = new Date()
      @modelChanged = false
      @setIntervalId = setInterval (=> @refreshInterlinear()), 1000
      @

    onClose: ->
      clearInterval @setIntervalId
      super

    # Check if we should refresh the interlinear display. We do so only if the
    # model has changed since our last interlinear refresh AND if the user has
    # been idle (no keydown events) for 2 seconds. Note: if we simply refresh
    # the IGT display on every keydown, we get an undesirable flash when the
    # default IGT field displays are refreshed and then hidden.
    refreshInterlinear: ->
      if @modelChanged and ((new Date()) - @lastKeydown) > 2000
        @modelChanged = false
        @interlinearize()

    # Form attribute labels and values have just been made visible. We trigger
    # a model change in order to effect a refresh of the interlinearization
    # display.
    contentAndLabelsVisiblePost: -> @model.trigger 'change'

    # Form attribute labels have just been hidden while the values are to still
    # be displayed. We trigger a model change in order to effect a refresh of
    # the interlinearization display.
    contentOnlyVisiblePost: -> @model.trigger 'change'

    keydown: (event) ->
      super event
      @lastKeydown = new Date()

    indicateModelState: ->
      super
      @modelChanged = true

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
      syntactic_category: SyntacticCategoryFieldDisplayView
      elicitation_method: ElicitationMethodFieldDisplayView
      date_elicited: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      speaker: SpeakerFieldDisplayView
      source: SourceFieldDisplayView
      elicitor: ElicitorFieldDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      verifier: VerifierFieldDisplayView
      collections: ArrayOfObjectsWithTitleFieldDisplayView
      tags: ArrayOfRelatedTagsFieldDisplayView
      files: ArrayOfRelatedFilesFieldDisplayView

    # Get an array of form attribute metadata (from the app settings model) for
    # the specified server type and category (e.g., 'igt' or 'secondary').
    getFormAttributes: (serverType, category) ->
      try
        globals.applicationSettings.get('resources')
          .forms.fieldsMeta[serverType][category]
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

    # The following methods effect the interlinearization of the form
    # attributes that are designated as "igt" attributes. The procedure involves
    # inspecting the IGT attributes as they are displayed via their default
    # field displays (cf. attribute2displayView), using the (length) data
    # gleaned from that to generate an HTML <table> representing the columnarly
    # aligned IGT data, and then hiding the original field display
    # representations. This works but it is not ideal since as a user updates
    # IGT data the to-be-hidden field displays are revealed and are only
    # re-hidden again when the interlinear display is refreshed after a period
    # of user inactivity. See the method `refreshInterlinear` for how this
    # works. For now I find this method of interlinearization acceptable.

    # The `ResourceView` base class calls this at the end of
    # `renderDisplayViews`.
    renderDisplayViewsPost: ->
      @interlinearize()

    interlinearizedHasContent: ->
      @$('div.igt-tables-container').first().html().length > 0

    # Transform the display of the form IGT attributes into an interlinear,
    # columnarly aligned display. This is done by creating a <table> for each
    # multi-field line in the IGT display.
    # Setting the `showIGTFields` param to `true` will result in the default
    # IGT field display views being made visible prior to the real
    # interlinearization transformation. This is usually not necessary because
    # these field views are, in general, visible prior to interlinearization;
    # however, when the visibility settings are being altered, then this
    # re-displaying is necessary.
    interlinearize: (showIGTFields=false) ->
      @labelWidth = null

      # Params
      @igtWordBuffer = 40 # How many pixels between IGT word columns.
      @igtRowStepIndent = 30 # How many pixels to indent each subsequent IGT row.
      @igtMaxIndentations = 5 # When we stop indenting IGT rows.
      @igtRowVerticalSpacer = 10 # How many pixels of vertical space between IGT rows.

      # Get info about IGT data (`igtMap`) and the longest word count (`wordCount`)
      [igtMap, wordCount] = @getIGTWords()

      # Show the IGT fields. Note that we call `visibility` on the primary
      # field display views so that the empty ones will be re-hidden and will
      # not clutter up the IGT display.
      if showIGTFields
        @showIGTFields igtMap
        for displayView in @primaryDisplayViews
          displayView.visibility()

      # If we only have one word, then there is no point in creating an
      # interlinear display.
      if wordCount < 2
        @linksAndPatternMatchesOnDefaultFieldDisplays igtMap
        return

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
        labelSelector = ".dative-field-display >
          .dative-field-display-label-container > label[for=#{attribute}]"
        $label = @$(labelSelector).first()
        title = $label.attr 'title'
        selector = ".dative-field-display >
          .dative-field-display-representation-container > .#{className}"
        $element = @$(selector).first()
        $element.css 'white-space', 'nowrap'

        # value = $element.text()
        value = @model.get(attribute) or '' # WARN: OLD-specific, cf. `getValue` of field.coffee.

        patternMatchIndices = @getPatternMatchIndices value, attribute
        words = value.split /\s+/
        if words.length > wordCount then wordCount = words.length
        igtMap[attribute] =
          className: className
          selector: selector
          value: value
          words: words
          title: title
          patternMatchIndices: patternMatchIndices
      [igtMap, wordCount]

    # If `attribute` matches a search that we are browsing, then
    # `getPatternMatchIndices` will return an array of 2-tuples containing
    # start and end indices for the ranges within the value of this attribute
    # that should be highlighted in order to indicate where the match(es) are.
    # N.B.: this indexed-based strategy is necessary because the "words" will be
    # split across distinct DOM nodes by the interlinear display (and possibly
    # also by the morpheme-interlinking anchor tags) yet the patterns matching
    # a field may span those node boundaries.
    getPatternMatchIndices: (value, attribute) ->
      if @searchPatternsObject
        regex = @searchPatternsObject[attribute]
        if regex
          indices = []
          valLen = value.length
          while match = regex.exec(value)
            l = match.index
            r = match.index + match[0].length
            pair = [l, r]
            prevPair = indices[(indices.length - 1)]

            # If the current match overlaps with the previous one but the
            # current one has a greater right-edge index, then we simply set
            # the previous match's right-edge index to the right-edge index of
            # the current match. This allows for overlapping matches to be
            # highlighted while also avoiding the creation of multiple
            # contiguous match pairs---that is, we don't want stuff like
            # `[[0, 1], [1, 2], [2, 3], ...]` generated from a regex like /./
            # since that would result in uneccessary extra computations as
            # well as Unicode combining characters being separated from their
            # base characters by <span> tags.
            if prevPair and (l >= prevPair[0]) and (l <= prevPair[1]) and
            (r >= prevPair[1])
              prevPair[1] = r
            else
              indices.push [l, r]

            # We break out of this loop if our current left-edge index is the
            # same as the current value's length. This is necessary because
            # calling `regex.exec str` for some regexes (e.g., `/((?:.*))/g`)
            # will result in an infinite loop.
            if l is valLen
              regex.lastIndex = 0
              break
            # We manually increment `regex.lastIndex` in order to get around
            # JavaScript's default behaviour, which is to set `lastIndex` to
            # the right edge of the previous match. We need to do this because
            # we need to account for overlapping matches.
            else
              regex.lastIndex = match.index + 1

          indices
        else
          null
      else
        null

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

        # The regex-replace here removes any `.igt-word`-classed <div>s in the
        # value. This is necessary because sometimes changing the field
        # displays can allow them to slip in.
        vector.originalValue = $igtLine.html()
          .replace(/<div class="igt-word">(.+?)<\/div>/g, '$1 ').trim()

        $igtLine.html wrappedValue
      igtMap

    # Unwrap the words that we had previously wrapped.
    unwrapIGTWords: (igtMap) ->
      for attribute, vector of igtMap
        @$(vector.selector).first()
          .html vector.originalValue
          .css 'white-space', 'normal'

    # A continuation of the `interlinearize` method meant to be called after a
    # 1 millisecond delay; this seems to be necessary because otherwise all of
    # the jQuery `.width()` calls will return 0.
    # TODO: RESEARCH: isn't there a jQuery `complete:` callback to handle this?
    _interlinearize: (igtMap) ->

      # We set the @labelWidth to a specific pixel value here.
      # WARN: this is very brittle but I had trouble dynamically discovering
      # the appropriate label width using jQuery inspections like the
      # following. Maybe this can be fixed ...
      # @labelWidth = @$(".dative-field-display").filter(':visible').first().width()
      # @labelWidth = @$(".resource-secondary-data .dative-field-display-label-container").filter(':visible').first().width()
      if not @labelWidth
        if @addUpdateType is 'add'
          @labelWidth = 196.5
        else
          @labelWidth = 181.8

      # Remove any information about IGT fields that are hidden.
      originalIGTMap = igtMap
      igtMap = @removeEmptyIGTLines igtMap

      # If there is only one IGT field with a value, then we should also
      # break from interlinearizing.
      if _.keys(igtMap).length < 2
        @unwrapIGTWords igtMap
        @clearIGTTables()
        @linksAndPatternMatchesOnDefaultFieldDisplays originalIGTMap
        return

      # Get an object that maps word indices to the longest word (cell) with
      # that index.
      wordWidths = @getIGTWordWidths igtMap

      tablesData = @getIGTTablesData wordWidths

      @displayIGTTables tablesData, igtMap, wordWidths

      @hideIGTFields igtMap

      @$('.morpheme-link.dative-tooltip').tooltip()

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
    # that will be present in that table. Here we divide the word indices into
    # arrays such that no IGT line (i.e., table) will exceed the width of the
    # containing <div>.
    getIGTTablesData: (wordWidths) ->
      maxWidth = @$('.resource-primary-data').first().width()
      if @dataLabelsVisible then maxWidth -= @labelWidth
      tablesData = []
      rowWidth = 0
      row = []
      lastIndex = _.keys(wordWidths).length - 1
      for index, wordWidth of wordWidths
        index = Number index
        rowWidth += wordWidth
        row.push index
        leftIndent = @getIGTTableLeftIndent tablesData.length
        if row.length is 1 then rowWidth += leftIndent
        if rowWidth > maxWidth and row.length > 1
          rowWidth = wordWidth
          row.pop()
          tablesData.push row[...]
          row = [index]
          rowWidth += leftIndent
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

    # Return the number of pixels that IGT table `index` should be indented to.
    getIGTTableLeftIndent: (index) ->
      if index < @igtMaxIndentations
        leftIndent = index * @igtRowStepIndent
      else
        leftIndent = @igtMaxIndentations * @igtRowStepIndent

    clearIGTTables: ->
      @$('div.igt-tables-container').html ''

    # Write the IGT data to the DOM as a series of IGT tables. There is one
    # table for each line of IGT, i.e., one table for each columnarly aligned
    # group of words.
    displayIGTTables: (tablesData, igtMap, wordWidths) ->
      $tablesContainer = $ '<div class="igt-tables-container">'
      for tableData, index in tablesData
        lastTable = if index is (tablesData.length - 1) then true else false
        leftIndent = @getIGTTableLeftIndent index
        $table = $ "<table class='igt-table' style='margin-bottom:
          #{@igtRowVerticalSpacer }px;'>"
        for attribute, vector of igtMap
          attrClass = "#{@utils.snake2hyphen attribute}-value"
          $row = $ '<tr>'
          if @dataLabelsVisible
            label ="<td class='dative-field-label-cell'
                style='width:#{@labelWidth}px;
                       min-width:#{@labelWidth}px;
                       max-width:#{@labelWidth}px;'
              ><label
                for='#{attribute}'
                class='dative-field-label dative-tooltip'
                title='#{vector.title}'
                >#{@utils.snake2regular attribute}</label></td>"
            $row.append $(label)
          for index, cellIndex in tableData
            word = vector.words[index]
            width = wordWidths[index]
            padding = ''
            if cellIndex is 0 then padding = "padding-left: #{leftIndent}px;"
            style = "style='width: #{width}px;
                            min-width: #{width}px;
                            max-width: #{width}px;
                            #{padding}'"

            wordPatternMatchIndices =
              @getWordPatternMatchIndices word, vector, index
            if attribute in ['morpheme_break', 'morpheme_gloss']
              word =
                @getMorphemesAsLinks(word, attribute, wordPatternMatchIndices)
            else
              word = @highlightWord word, wordPatternMatchIndices

            firstWord = index is 0
            lastWord = false
            if lastTable and cellIndex is (tableData.length - 1)
              lastWord = true
            [prefix, suffix] =
              @getAffixes attribute, firstWord, lastWord

            $row.append $("<td class='igt-word-cell #{attrClass}'
              #{style}>#{prefix}#{word}#{suffix}</td>")

          $table.append $row
        $tablesContainer.append $table

      @$('.resource-primary-data .igt-tables-container').first()
        .html $tablesContainer.html()

      @$('label.dative-tooltip')
        .tooltip
          position:
            my: "right-300 top"
            at: 'right top'
            collision: 'flipfit'

    # Return a 2-tuple `[prefix, suffix]` to circumfix around the word. This
    # takes care of the "/" around the morpheme_break as well as the
    # grammaticality before the transcription. Params `firstWord` and
    # `lastWord` are booleans indicating whether the affixes we are returning
    # are for the first word and/or last word of a form.
    getAffixes: (attribute, firstWord, lastWord) ->
      prefix = ''
      suffix = ''
      if firstWord
        switch attribute
          when 'transcription'
            prefix = @model.get('grammaticality') or ''
            if @searchPatternsObject
              regex = @searchPatternsObject.grammaticality
              if regex then prefix = @utils.highlightSearchMatch regex, prefix
          when 'morpheme_break'
            prefix = '/'
          when 'phonetic_transcription'
            prefix = '['
          when 'narrow_phonetic_transcription'
            prefix = '['
      if lastWord
        switch attribute
          when 'morpheme_break'
            suffix = '/'
          when 'phonetic_transcription'
            suffix = ']'
          when 'narrow_phonetic_transcription'
            suffix = ']'
      [prefix, suffix]

    # Enclose substrings of `word` in highlighting <span> tags. These
    # substrings are the ones that match any search parameters.
    highlightWord: (word, wordPatternMatchIndices) ->
      if wordPatternMatchIndices.length > 0
        pieces = []
        left = 0
        for [start, end], index in wordPatternMatchIndices
          if start isnt 0 then pieces.push word[left...start]
          pieces.push "<span class='dative-state-highlight'>"
          pieces.push word[start...end]
          pieces.push "</span>"
          left = end
          if index is wordPatternMatchIndices.length - 1 and
          end isnt (word.length - 1)
            pieces.push word[end...]
        pieces.join('')
      else
        word

    # Enclose substrings of `morpheme` in highlighting <span> tags. These
    # substrings are the ones that match any search parameters.
    highlightMorpheme: (morpheme, morphPatternMatchIndices) ->
      if morphPatternMatchIndices.length > 0
        pieces = []
        left = 0
        for [start, end], index in morphPatternMatchIndices
          if start isnt 0 then pieces.push morpheme[left...start]
          pieces.push "<span class='dative-state-highlight'>"
          pieces.push morpheme[start...end]
          pieces.push "</span>"
          left = end
          if index is morphPatternMatchIndices.length - 1 and
          end isnt (morpheme.length - 1)
            pieces.push morpheme[end...]
        pieces.join('')
      else
        morpheme

    # Return an array of 2-tuples of the form [start-index, end-index] which
    # describe the start and end points of any pattern-matching substrings
    # within `word`. Used for highlighting pattern matches.
    # - `sentIndex`: the index of the word in the sentence-as-an-array-of-words
    # - `vector`   : an array of data about the sentence
    # - `wStart`   : the start index of the *word* within the sentence-as-string
    # - `wEnd`     : the end index of the *word* within the sentence-as-string
    # - `pStart`   : the start index of the *pattern* within the sentence-as-string
    # - `pEnd`     : the end index of the *pattern* within the sentence-as-string
    getWordPatternMatchIndices: (word, vector, sentIndex) ->
      wordPatternMatchIndices = []
      if vector.patternMatchIndices
        wStart = vector.words[...sentIndex].join(' ').length + 1
        if sentIndex is 0 then wStart -= 1
        wEnd = wStart + word.length
        for [pStart, pEnd] in vector.patternMatchIndices
          if (wStart <= pStart and wEnd > pStart) or
          (wStart > pStart and wStart < pEnd) # used to be `wStart <= pEnd`
            tmp = pStart - wStart
            if tmp < 0 then tmp = 0
            wordPatternMatchIndex = [tmp]
            if pEnd > wEnd
              wordPatternMatchIndex.push word.length
            else
              wordPatternMatchIndex.push (word.length - (wEnd - pEnd))
            wordPatternMatchIndices.push wordPatternMatchIndex
      wordPatternMatchIndices

    # Return an array of 2-tuples of the form [start-index, end-index] which
    # describe the start and end points of any pattern-matching substrings
    # within `morpheme`. Used for highlighting pattern matches within
    # individual morphemes, which is necessary when morphemes are enclosed in
    # <a> tags for morpheme inter-linking.
    # - `wordPatternMatchIndices`: array of 2-tuples of indices indicating
    #    where search patterns match in the word
    # - `morphemes`: array of morphemes (including delimiters)
    # - `morphIndex`: the index of the morpheme in the word-as-an-array-of-morphemes
    # - `mStart`   : the start index of the *morpheme* within the word-as-string
    # - `mEnd`     : the end index of the *morpheme* within the word-as-string
    # - `pStart`   : the start index of a *pattern* within the word-as-string
    # - `pEnd`     : the end index of a *pattern* within the word-as-string
    getMorphemePatternMatchIndices: (morpheme, wordPatternMatchIndices,
    morphemes, morphIndex) ->
      morphPatternMatchIndices = []
      if wordPatternMatchIndices.length > 0
        mStart = morphemes[...morphIndex].join('').length
        mEnd = mStart + morpheme.length
        for [pStart, pEnd] in wordPatternMatchIndices
          if (mStart <= pStart and mEnd > pStart) or
          (mStart > pStart and mStart < pEnd)
            tmp = pStart - mStart
            if tmp < 0 then tmp = 0
            morphPatternMatchIndex = [tmp]
            if pEnd > mEnd
              morphPatternMatchIndex.push morpheme.length
            else
              morphPatternMatchIndex.push (morpheme.length - (mEnd - pEnd))
            morphPatternMatchIndices.push morphPatternMatchIndex
      morphPatternMatchIndices

    # Transform morphemes into links on the default field display views. This
    # method should be called in the cases where IGT tabularization is not
    # appropriate but where we still want the morphemes to be links that
    # trigger the rendering of `FormView`s in dialog boxes.
    linksAndPatternMatchesOnDefaultFieldDisplays: (igtMap) ->
      for attribute in @getFormAttributes @activeServerType, 'igt'
        className = @utils.snake2hyphen attribute # WARN: OLD-specific
        selector = ".dative-field-display >
          .dative-field-display-representation-container > .#{className}"
        $element = @$(selector).first()
        value = @model.get attribute
        if value
          words = value.split /\s+/
          newValue = []
          for word, index in words
            wordPatternMatchIndices =
              @getWordPatternMatchIndices word, igtMap[attribute], index
            if attribute in ['morpheme_break', 'morpheme_gloss']
              newWord =
                @getMorphemesAsLinks word, attribute, wordPatternMatchIndices
            else
              newWord = @highlightWord word, wordPatternMatchIndices

            firstWord = index is 0
            lastWord = if index is (words.length - 1) then true else false
            [prefix, suffix] =
              @getAffixes attribute, firstWord, lastWord

            newValue.push "#{prefix}#{newWord}#{suffix}"
          $element.html newValue.join(' ')
      @$('.morpheme-link.dative-tooltip').tooltip()

    # Transform `word` into a string of HTML containing anchors that, when
    # clicked, trigger the display of relevant forms in dialog boxes. This is
    # the logic that makes perfect matches into "blue" links and partial ones
    # into "green" links. Note that it depends on the OLD's `morpheme_break_ids`
    # and `morpheme_gloss_ids` attributes.
    getMorphemesAsLinks: (word, attribute, wordPatternMatchIndices=[]) ->
      try
        @_getMorphemesAsLinks(word, attribute, wordPatternMatchIndices)
      catch e
        console.log 'Error in getting morphemes as links ...'
        console.log e
        word

    _getMorphemesAsLinks: (word, attribute, wordPatternMatchIndices) ->

      result = []

      # TODO: this should be based on delimiters in app settings ...
      delims = ['-', '=']
      splitter = new RegExp "(#{delims.join '|'})"

      if attribute in ['morpheme_break', 'morpheme_gloss']
        value = @model.get attribute
        words = value.split /\s+/
        index = words.indexOf word
        if index is -1
          result.push word
        else
          linkData = @model.get("#{attribute}_ids")?[index]
          morphemes = word.split splitter
          morphemeCount = (m for m in morphemes when m not in delims).length
          morphIndex = 0
          for morpheme, morphDelimIndex in morphemes
            morphPatternMatchIndices = @getMorphemePatternMatchIndices(
              morpheme, wordPatternMatchIndices, morphemes, morphDelimIndex)
            if morpheme in delims
              result.push @highlightMorpheme morpheme, morphPatternMatchIndices
            else
              if linkData
                morphLinkData = linkData[morphIndex]
                if morphLinkData.length > 0
                  matchType = @getMatchType attribute, index, morphIndex
                  [id, meta, tooltip] =
                    @getIdMetaTooltip morphLinkData, attribute
                  morphemeLink = "<a
                    class='dative-tooltip morpheme-link
                      morpheme-link-#{matchType}-match'
                    title='#{meta}. #{tooltip}'
                    href='javascript:;'
                    data-id='#{id}'
                    >#{@highlightMorpheme morpheme, morphPatternMatchIndices}</a>"
                  result.push morphemeLink
                else
                  result.push(@highlightMorpheme(morpheme,
                    morphPatternMatchIndices))
              else
                result.push(@highlightMorpheme(morpheme,
                  morphPatternMatchIndices))
              morphIndex += 1
        result.join ''
      else
        word

    # Process `morphLinkData` (an array of arrays that encode information about
    # which morphemes in the database match the morpheme under inspection) and
    # return:
    # - `id`: a string of comma-delimited integer ids,
    # - `meta`: a string listing the matches for this morpheme shape/gloss, and
    # - `tooltip`: a tooltip string to indicate what the link does.
    getIdMetaTooltip: (morphLinkData, attribute) ->
      meta = ("‘#{x[1]}’ (#{x[2]})" for x in morphLinkData)
        .join '; '
        .replace /'/g, '&apos;'
      id = (x[0] for x in morphLinkData).join ','
      type = if attribute is 'morpheme_break' then 'shape' else 'gloss'
      if morphLinkData.length is 1
        tooltip = "Click to view the morpheme that matches this #{type}."
      else
        tooltip = "Click to view the morphemes that match this #{type}."
      [id, meta, tooltip]

    # Does the morpheme have a perfect match in the database or only a partial
    # one? Each morpheme shape/gloss has an array of 3-tuple arrays that
    # encodes its matches. A morpheme shape is a perfect match if its morpheme
    # gloss counterpart match array contains all of the ids that it contains.
    getMatchType: (attribute, index, morphIndex) ->
      if attribute is 'morpheme_break'
        counterpart = 'morpheme_gloss'
      else
        counterpart = 'morpheme_break'
      myMatches = @model.get("#{attribute}_ids")[index][morphIndex]
      counterpartMatches = @model.get("#{counterpart}_ids")[index][morphIndex]
      myMatchIds = (m[0] for m in myMatches)
      counterpartMatchIds = (m[0] for m in counterpartMatches)
      response = 'perfect'
      for id in myMatchIds
        if id not in counterpartMatchIds
          response = 'partial'
      response

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

    # Show the standard field displays for the IGT fields.
    showIGTFields: (igtMap) ->
      # TODO: we should actually just tell the relevant IGT views to show
      # themselves; however, this requires keeping an attribute-based dict to
      # them in the form superview, which we currently don't do ...
      igtClasses = (".dative-field-display-representation-container >
        .#{v.className}" for v in _.values igtMap).join ', '
      @$('.dative-field-display').each (index, element) =>
        $element = @$ element
        if $element.has(igtClasses).length then $element.show()


    # Keys are the CamelCase names of resources that forms have relations to
    # and the values are the attributes of forms that are valuated as
    # references to a resource or set of resources in that resource collection.
    relatedResources:
      'ElicitationMethod': ['elicitation_method']
      'User': ['elicitor', 'enterer', 'modifier', 'verifier']
      'Source': ['source']
      'Speaker': ['speaker']
      'SyntacticCategory': ['syntactic_category']
      'Tag': ['tags']
      'File': ['files']

