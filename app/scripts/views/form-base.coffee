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

    # A user has clicked on a morpheme link so we cause that morpheme (or those
    # morphemes) to be displayed using one or more FormViews in one or more
    # dialogs.
    morphemeLinkClicked: (event) ->
      @stopEvent event
      try
        id = (parseInt(x) for x in @$(event.target).attr('data-id').split(','))
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
      setInterval (=> @refreshInterlinear()), 1000
      @

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
    #
    # The following methods effect the interlinearization of the form
    # attributes that are designated as "igt" attributes. The procedure involves
    # inspecting the IGT attributes as they are displayed via their default
    # field displays (cf. attribute2displayView), using the data gleaned from
    # that to generate an HTML <table> representing the columnarly aligned IGT
    # data, and then hiding the original field display representations. This
    # works but it is not ideal since as a user updates IGT data the
    # to-be-hidden field displays are revealed and are only re-hidden again
    # when the interlinear display is refreshed after a period of user
    # inactivity. See the method `refreshInterlinear` for how this works.

    # The `ResourceView` base class calls this at the end of
    # `renderDisplayViews`.
    renderDisplayViewsPost: ->
      @interlinearize()

    # Transform the display of the form IGT attributes into an interlinear,
    # columnarly aligned display. This is done by creating a <table> for each
    # multi-field line in the IGT display.
    interlinearize: ->

      @labelWidth = null

      # Params
      @igtWordBuffer = 40 # How many pixels between IGT word columns.
      @igtRowStepIndent = 30 # How many pixels to indent each subsequent IGT row.
      @igtMaxIndentations = 5 # When we stop indenting IGT rows.
      @igtRowVerticalSpacer = 10 # How many pixels of vertical space between IGT rows.

      # Get info about IGT data (`igtMap`) and the longest word count (`wordCount`)
      [igtMap, wordCount] = @getIGTWords()

      # If we only have one word, then there is no point in creating an
      # interlinear display.
      if wordCount < 2
        @createMorphemeLinksOnDefaultFieldDisplays()
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
        value = $element.text()
        words = value.split /\s+/
        if words.length > wordCount then wordCount = words.length
        igtMap[attribute] =
          className: className
          selector: selector
          value: value
          words: words
          title: title
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
      igtMap = @removeEmptyIGTLines igtMap

      # If there is only one IGT field with a value, then we should also
      # break from interlinearizing.
      # TODO: we should also remove the <div>-wrapping performed above.
      if _.keys(igtMap).length < 2
        @unwrapIGTWords igtMap
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

    # Write the IGT data to the DOM as a series of IGT tables. There is one
    # table for each line of IGT, i.e., one table for each columnarly aligned
    # group of words.
    displayIGTTables: (tablesData, igtMap, wordWidths) ->
      $tablesContainer = $ '<div class="igt-tables-container">'
      for tableData, index in tablesData
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
                >#{attribute}</label></td>"
            $row.append $(label)
          for index, cellIndex in tableData
            word = vector.words[index]
            width = wordWidths[index]
            padding = ''
            if cellIndex is 0 then padding = "padding-left: #{leftIndent}px;'"
            style = "style='width: #{width}px;
                            min-width: #{width}px;
                            max-width: #{width}px;
                            #{padding}'"
            word = @getMorphemesAsLinks word, attribute
            $row.append $("<td class='igt-word-cell #{attrClass}'
              #{style}>#{word}</td>")
          $table.append $row
        $tablesContainer.append $table
      $extantIGTContainer =
        @$('.resource-primary-data .igt-tables-container').first()
      if $extantIGTContainer.length > 0
        $extantIGTContainer.html $tablesContainer.html()
      else
        @$('.resource-primary-data').first().prepend $tablesContainer

      @$('label.dative-tooltip')
        .tooltip
          position:
            my: "right-300 top"
            at: 'right top'
            collision: 'flipfit'

    # Transform morphemes into links on the default field display views. This
    # method should be called in the cases where IGT tabularization is not
    # appropriate but where we still want the morphemes to be links that
    # trigger the rendering of `FormView`s in dialog boxes.
    createMorphemeLinksOnDefaultFieldDisplays: ->
      for attribute in @getFormAttributes @activeServerType, 'igt'
        if attribute in ['morpheme_break', 'morpheme_gloss']
          className = @utils.snake2hyphen attribute # WARN: OLD-specific
          selector = ".dative-field-display >
            .dative-field-display-representation-container > .#{className}"
          $element = @$(selector).first()
          value = $element.text()
          words = value.split /\s+/
          newValue = []
          for word in words
            newWord = @getMorphemesAsLinks word, attribute
            newValue.push newWord
          $element.html newValue.join(' ')
      @$('.morpheme-link.dative-tooltip').tooltip()

    # Transform `word` into a string of HTML containing anchors that, when
    # clicked, trigger the display of relevant forms in dialog boxes. This is
    # the logic that makes perfect matches into "blue" links and partial ones
    # into "green" links. Note that it depends on the OLD's `morpheme_break_ids`
    # and `morpheme_gloss_ids` attributes.
    getMorphemesAsLinks: (word, attribute) ->
      try
        @_getMorphemesAsLinks word, attribute
      catch
        word

    _getMorphemesAsLinks: (word, attribute) ->

      result = []

      # TODO: this should be based on delimiters in app settings ...
      delims = ['-', '=']
      splitter = new RegExp "(#{delims.join '|'})"

      if attribute in ['morpheme_break', 'morpheme_gloss']
        @prefix = @suffix = ''
        value = @model.get attribute
        words = value.split /\s+/
        index = words.indexOf word
        if index is -1
          [word, index] = @morphemeBreakIndexRepair word, words
        if index is -1
          result.push word
        else
          linkData = @model.get("#{attribute}_ids")[index]
          morphemes = word.split splitter
          morphemeCount = (m for m in morphemes when m not in delims).length
          morphIndex = 0
          for morpheme in morphemes
            if morpheme in delims
              result.push morpheme
            else
              morphLinkData = linkData[morphIndex]
              if morphLinkData.length > 0
                matchType = @getMatchType attribute, index, morphIndex
                # morphLinkData = morphLinkData[0]
                [id, meta] = @getIdMeta morphLinkData
                morphemeLink = "<a
                  class='dative-tooltip morpheme-link
                    morpheme-link-#{matchType}-match'
                  title='#{meta}. Click to view this morpheme in the page'
                  href='javascript:;'
                  data-id='#{id}'>#{morpheme}</a>"
                result.push(@affixRepair(morphemeLink, index, morphIndex,
                  words, morphemeCount))
              else
                result.push(@affixRepair(morpheme, index, morphIndex, words,
                  morphemeCount))
              morphIndex += 1
        result.join ''
      else
        word

    getIdMeta: (morphLinkData) ->
      meta = ("‘#{x[1]}’ (#{x[2]})" for x in morphLinkData)
        .join '; '
        .replace "'", '&apos;'
      id = (x[0] for x in morphLinkData).join ','
      [id, meta]

    # Restore the affixes to the IGT line, e.g., the "/" that enclose morpheme
    # break values.
    affixRepair: (morpheme, wordIndex, morphIndex, words, morphemeCount) ->
      if wordIndex is 0 and morphIndex is 0
        morpheme = "#{@prefix}#{morpheme}"
      if wordIndex is (words.length - 1) and
      morphIndex is (morphemeCount - 1)
        morpheme = "#{morpheme}#{@suffix}"
      morpheme

    # If word begins or ends with '/', then this may have been caused by prior
    # formatting on the morpheme break value. We attempt to compensate for that
    # here.
    morphemeBreakIndexRepair: (word, words) ->
      if word[0] is '/'
        @prefix = '/'
        word = word[1...]
        index = words.indexOf word
      else
        @prefix = ''
      if word[word.length - 1] is '/'
        @suffix = '/'
        word = word[...-1]
        index = words.indexOf word
      else
        @suffix = ''
      [word, index]

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

