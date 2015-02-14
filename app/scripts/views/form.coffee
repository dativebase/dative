define [
  'backbone'
  './base'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/form'
], (Backbone, BaseView, globals, tooltips, formTemplate) ->

  # Form View
  # ---------
  #
  # For displaying individual forms with an IGT interface.

  class FormView extends BaseView

    template: formTemplate
    tagName: 'div'
    className: 'dative-form-widget dative-widget-center ui-widget
      ui-widget-content ui-corner-all'

    initialize: ->
      @secondaryDataVisible = false # comments, tags, etc.
      @headerVisible = false # the header full of buttons
      @primaryDataLabelsVisible = false # labels for primary data fields

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @model, 'change', @render
      @listenTo Backbone, 'form:dehighlightAllFormViews', @dehighlight
      @listenTo Backbone, 'formsView:expandAllForms', @expand
      @listenTo Backbone, 'formsView:collapseAllForms', @collapse

    events:
      'click .form-primary-data': 'showAndHighlightOnlyMe'
      'mouseenter .form-primary-data': 'mouseenterPrimaryData'
      'mouseleave .form-primary-data': 'mouseleavePrimaryData'
      'click .hide-form-details': 'hideFormDetails'
      'click .toggle-secondary-data': 'toggleSecondaryDataAnimate'
      'click .toggle-primary-data-labels': 'togglePrimaryDataLabelsAnimate'
      'focus': 'focus'
      'focusout': 'focusout'
      'keydown': 'keydown'

    render: ->
      #console.log @getDatumFieldValue('dateElicited')
      console.log @getFieldDBDatumValue(@model.toJSON(), 'dateElicited')
      @html()
      @guify()
      @listenToEvents()
      @

    html: ->
      context = @getContext()
      @$el
        .attr
          'id': @model.cid
          'tabindex': 0
        .html @template(context)

    # Context object for the template.
    getContext: ->
      context = _.extend(@model.toJSON(), {
        activeServerType: @getActiveServerType()
        h: # "h" for "helpers"
          tooltips: tooltips
          fieldDB:
            getDatumField: @getDatumField
            getDatumFieldValue: @getDatumFieldValue
            datumFieldsHasValue: @datumFieldsHasValue
            getDatumFieldLabel: @getDatumFieldLabel
            getFieldDBTooltip: @getFieldDBTooltip
            fieldDBAlreadyDisplayedFields: @fieldDBAlreadyDisplayedFields()
            fieldDBFormIGTAttributes: @fieldDBFormIGTAttributes
            fieldDBFormSecondaryAttributes: @fieldDBFormSecondaryAttributes
            fieldDBUtteranceJudgementFieldDisplay: @fieldDBUtteranceJudgementFieldDisplay
            fieldDBMorphemesFieldDisplay: @fieldDBMorphemesFieldDisplay
            fieldDBGlossFieldDisplay: @fieldDBGlossFieldDisplay
            fieldDBStringFieldDisplay: @fieldDBStringFieldDisplay
            fieldDBCommentsFieldDisplay: @fieldDBCommentsFieldDisplay
            fieldDBDateFieldDisplay: @fieldDBDateFieldDisplay
            fieldDBModifiersArrayFieldDisplay: @fieldDBModifiersArrayFieldDisplay

          old:
            oldFormIGTAttributes: @oldFormIGTAttributes
            oldFormSecondaryAttributes: @oldFormSecondaryAttributes
            oldStringFieldDisplay: @oldStringFieldDisplay
            oldObjectWithNameFieldDisplay: @oldObjectWithNameFieldDisplay
            oldSourceFieldDisplay: @oldSourceFieldDisplay
            oldArrayOfObjectsWithNameFieldDisplay:
              @oldArrayOfObjectsWithNameFieldDisplay
            oldArrayOfObjectsWithTitleFieldDisplay:
              @oldArrayOfObjectsWithTitleFieldDisplay
            oldDateFieldDisplay: @oldDateFieldDisplay
            oldPersonFieldDisplay: @oldPersonFieldDisplay
            oldPhoneticTranscriptionFieldDisplay:
              @oldPhoneticTranscriptionFieldDisplay
            oldTranscriptionGrammaticalityFieldDisplay:
              @oldTranscriptionGrammaticalityFieldDisplay
            oldMorphemeBreakFieldDisplay: @oldMorphemeBreakFieldDisplay
            oldMorphemeGlossFieldDisplay: @oldMorphemeGlossFieldDisplay
          encloseIfNotAlready: @utils.encloseIfNotAlready
          timeSince: @utils.timeSince
          humanDatetime: @utils.humanDatetime
          humanDate: @utils.humanDate
          displayNoneStyle: @displayNoneStyle
      })
      context.datetimeEntered = @utils.dateString2object(
        context.datetimeEntered)
      context.datetimeModified = @utils.dateString2object(
        context.datetimeModified)
      context.dateElicited = @utils.dateString2object(context.dateElicited)
      context

    styleDisplayNone: ' style="display: none;" '

    # Return an in-line CSS style to hide the HTML of an empty form attribute
    # Note the use of `=>` so that the ECO template knows to use this view's context.
    displayNoneStyle: (value) =>
      if _.isDate(value) or _.isNumber(value)
        ''
      else if _.isEmpty(value) or @isValueless(value)
        @styleDisplayNone
      else
        ''

    # Returns `true` only if thing is an object all of whose values are either
    # `null` or empty strings.
    isValueless: (thing) ->
      _.isObject(thing) and
      (not _.isArray(thing)) and
      _.isEmpty(_.filter(_.values(thing), (x) -> x isnt null and x isnt ''))

    guify: ->
      @primaryDataLabelsVisibility()
      @guifyButtons()
      @tooltipify()
      @headerVisibility()
      @secondaryDataVisibility()

    headerVisibility: ->
      if @headerVisible
        @showHeader()
        @turnOffPrimaryDataTooltip()
      else
        @hideHeader()
        @turnOnPrimaryDataTooltip()

    secondaryDataVisibility: ->
      if @secondaryDataVisible
        @showSecondaryData()
      else
        @hideSecondaryData()

    # Hide/show the labels for the primary data, e.g., transcription/utterance,
    # translation(s), etc.
    togglePrimaryDataLabelsAnimate: ->
      if @primaryDataLabelsVisible
        @hidePrimaryContentAndLabelsThenShowContent()
      else
        @hidePrimaryContentAndLabelsThenShowAll()

    # Fade out primary data, then fade in primary data and labels.
    hidePrimaryContentAndLabelsThenShowAll: ->
      @$(@primaryDataContentSelector).fadeOut
        complete: =>
          @showPrimaryDataLabelsAnimate()
          @showPrimaryDataContentAnimate()

    # Fade out primary data and labels, then fade in primary data.
    hidePrimaryContentAndLabelsThenShowContent: ->
      @hidePrimaryDataLabelsAnimate()
      @$(@primaryDataContentSelector).fadeOut
        complete: =>
          @showPrimaryDataContentAnimate()

    # Fade in primary data content.
    showPrimaryDataContentAnimate: ->
      @$(@primaryDataContentSelector).fadeIn()

    setPrimaryDataLabelsButtonStateClosed: ->
      @$('.toggle-primary-data-labels')
        .button()
        .tooltip
          items: 'button'
          content: 'show labels'

    setPrimaryDataLabelsButtonStateOpen: ->
      @$('.toggle-primary-data-labels')
        .button()
        .tooltip
          items: 'button'
          content: 'hide labels'

    primaryDataLabelsSelector: '.form-igt-data-label,
      .form-translations-data-label, .form-translation-data-label'

    primaryDataContentSelector: '.form-igt-data-content,
      .form-translations-data-content, .form-translation-data-content'

    showPrimaryDataLabelsAnimate: ->
      @primaryDataLabelsVisible = true
      @setPrimaryDataLabelsButtonStateOpen()
      @$(@primaryDataLabelsSelector).fadeIn()

    hidePrimaryDataLabelsAnimate: (event) ->
      @primaryDataLabelsVisible = false
      @setPrimaryDataLabelsButtonStateClosed()
      @$(@primaryDataLabelsSelector).fadeOut()

    primaryDataLabelsVisibility: ->
      if @primaryDataLabelsVisible
        @showPrimaryDataLabels()
      else
        @hidePrimaryDataLabels()

    togglePrimaryDataLabels: ->
      if @primaryDataLabelsVisible
        @hidePrimaryDataLabels()
      else
        @showPrimaryDataLabels()

    hidePrimaryDataLabels: ->
      @primaryDataLabelsVisible = false
      @setPrimaryDataLabelsButtonStateClosed()
      @$(@primaryDataLabelsSelector).hide()

    showPrimaryDataLabels: ->
      @primaryDataLabelsVisible = true
      @setPrimaryDataLabelsButtonStateOpen()
      @$(@primaryDataLabelsSelector).show()

    tooltipify: ->

      @$('.form-fielddb-modifier-timestamp.dative-tooltip')
        .tooltip
          items: 'span'
          position:
            my: "left top"
            at: "right top"
            collision: "flipfit"

      @$('.form-secondary-data,.form-igt-data,.form-translations-data .dative-tooltip')
        .not '.form-fielddb-modifier-timestamp'
        .tooltip
          items: 'div, span'
          position:
            my: "right top"
            at: "left top"
            collision: "flipfit"

    guifyButtons: ->

      @$('button.hide-form-details')
        .button()
        .tooltip
          items: 'button'
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.toggle-secondary-data')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

      @$('button.toggle-primary-data-labels')
        .button()
        .tooltip
          position:
            my: "right-80 center"
            at: "left center"
            collision: "flipfit"

      @$('button.update-form')
        .button()
        .tooltip
          position:
            my: "left+220 center"
            at: "right center"
            collision: "flipfit"

      @$('button.associate-form')
        .button()
        .tooltip
          position:
            my: "left+185 center"
            at: "right center"
            collision: "flipfit"

      @$('button.export-form')
        .button()
        .tooltip
          position:
            my: "left+150 center"
            at: "right center"
            collision: "flipfit"

      @$('button.remember-form')
        .button()
        .tooltip
          position:
            my: "left+115 center"
            at: "right center"
            collision: "flipfit"

      @$('button.delete-form')
        .button()
        .tooltip
          position:
            my: "left+80 center"
            at: "right center"
            collision: "flipfit"

      @$('button.duplicate-form')
        .button()
        .tooltip
          position:
            my: "left+45 center"
            at: "right center"
            collision: "flipfit"

      @$('button.form-history')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

    expand: ->
      @$el.addClass 'expanded'
      @showSecondaryDataEvent = 'form:formExpanded' # FormsView listens for this once in order to scroll to the correct place
      @showFullAnimate()

    collapse: ->
      @$el.removeClass 'expanded'
      @hideSecondaryDataEvent = 'form:formCollapsed' # FormsView listens for this once in order to scroll to the correct place
      @hideFullAnimate()

    highlightAndShow: ->
      @highlight()
      @showSecondaryData()

    showAndHighlightOnlyMe: ->
      if not @headerVisible
        @showFullAnimate()
        @highlightOnlyMe()

    highlight: ->
      @$el.addClass 'ui-state-highlight'

    highlightOnlyMe: ->
      @dehighlightAll()
      @highlight()

    dehighlightAll: ->
      Backbone.trigger 'form:dehighlightAllFormViews'

    dehighlight: ->
      @$el.removeClass 'ui-state-highlight'

    dehighlightAndHide: ->
      @dehighlight()
      @hideSecondaryData()

    focus: ->
      @highlightOnlyMe()

    focusout: ->
      @dehighlight()

    # <Enter> on a closed and form opens it, <Esc> on an open form closes it.
    keydown: (event) ->
      if @headerVisible
        if event.which is 27 then @hideFormDetails()
      else
        if event.which is 13 then @showFullAnimate()

    ############################################################################
    # Hide & Show stuff
    ############################################################################

    # Hide details and self-focus. Clicking on the double-angle-up
    # (hide-form-details) button calls this, as does `@keydown`.
    hideFormDetails: ->
      @hideFullAnimate()
      @$el.focus()

    # Full = border, header & secondary data
    ############################################################################

    showFull: ->
      @addBorder()
      @turnOffPrimaryDataTooltip()
      @showHeader()
      @showSecondaryData()

    hideFull: ->
      @removeBorder()
      @turnOnPrimaryDataTooltip()
      @hideHeader()
      @hideSecondaryData()

    showFullAnimate: ->
      @addBorderAnimate()
      @turnOffPrimaryDataTooltip()
      @showHeaderAnimate()
      @showSecondaryDataAnimate()

    hideFullAnimate: ->
      @removeBorderAnimate()
      @turnOnPrimaryDataTooltip()
      @hideHeaderAnimate()
      @hideSecondaryDataAnimate()

    # Header
    ############################################################################

    showHeader: ->
      @headerVisible = true
      @$('.dative-widget-header').first().show()

    hideHeader: ->
      @headerVisible = false
      @$('.dative-widget-header').first().hide()

    showHeaderAnimate: ->
      @headerVisible = true
      @$('.dative-widget-header').first().slideDown()

    hideHeaderAnimate: ->
      @headerVisible = false
      @$('.dative-widget-header').first().slideUp()

    # Secondary Data
    ############################################################################

    showSecondaryData: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorder()
      @$('.form-secondary-data').show()

    hideSecondaryData: ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @removeBorder()
      @$('.form-secondary-data').hide()

    toggleSecondaryData: ->
      if @secondaryDataVisible
        @hideSecondaryData()
      else
        @showSecondaryData()

    showSecondaryDataAnimate: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorderAnimate()
      @$('.form-secondary-data').slideDown
        complete: =>
          # FormsView listens once for this and fixes scroll position and focus in response
          if @showSecondaryDataEvent
            Backbone.trigger @showSecondaryDataEvent
            @showSecondaryDataEvent = null

    hideSecondaryDataAnimate: (event) ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @$('.form-secondary-data').slideUp
        complete: =>
          # FormsView listens once for this and fixes scroll position and focus in response
          if @hideSecondaryDataEvent
            Backbone.trigger @hideSecondaryDataEvent
            @hideSecondaryDataEvent = null

    toggleSecondaryDataAnimate: ->
      if @secondaryDataVisible
        @hideSecondaryDataAnimate()
      else
        @showSecondaryDataAnimate()

    # Border
    ############################################################################

    addBorder: ->
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

    removeBorder: ->
      @$el.css 'border-color': 'transparent'

    addBorderAnimate: ->
      @$el.animate 'border-color': @constructor.jQueryUIColors().defBo

    removeBorderAnimate: ->
      @$el.animate 'border-color': 'transparent'

    setSecondaryDataButtonStateClosed: ->
      @$('.toggle-secondary-data')
        .find('i').removeClass('fa-angle-up').addClass('fa-angle-down').end()
        .button()
        .tooltip
          items: 'button'
          content: 'show the secondary data of this form'

    setSecondaryDataButtonStateOpen: ->
      @$('.toggle-secondary-data')
        .find('i').removeClass('fa-angle-down').addClass('fa-angle-up').end()
        .button()
        .tooltip
          items: 'button'
          content: 'hide the secondary data of this form'


    # Primary Data
    ############################################################################

    mouseenterPrimaryData: ->
      if not @headerVisible
        @$('.form-primary-data').css 'cursor', 'pointer'
      else
        @$('.form-primary-data').css 'cursor', 'text'

    mouseleavePrimaryData: ->
      if not @headerVisible
        @$('.form-primary-data').css 'cursor', 'text'

    turnOnPrimaryDataTooltip: ->
      $primaryDataDiv = @$('.form-primary-data').first()
      if not $primaryDataDiv.tooltip 'instance'
        $primaryDataDiv
          .tooltip
            open: (event, ui) -> ui.tooltip.css "max-width", "200px"
            items: 'div'
            content: ['Click here to reveal controls for, and more information',
              'about, this form.'].join ' '
            position:
              my: 'right-10 center'
              at: 'left center'
              collision: 'flipfit'

    turnOffPrimaryDataTooltip: ->
      $primaryDataDiv = @$('.form-primary-data').first()
      if $primaryDataDiv.tooltip 'instance'
        $primaryDataDiv.tooltip 'destroy'

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'


    ############################################################################
    # OLD-specific template helpers
    ############################################################################

    # The following methods are all responsible for writing OLD field labels and
    # values to the DOM.

    # IGT OLD Form Attributes.
    # This array defines the "IGT" attributes of an OLD form (along with their
    # order). These are those that will be aligned into columns of one word
    # each. This array should be made user-configurable at some point.
    oldFormIGTAttributes: [
      ['narrow_phonetic_transcription', 'oldPhoneticTranscriptionFieldDisplay']
      ['phonetic_transcription',        'oldPhoneticTranscriptionFieldDisplay']
      ['transcription',                 'oldTranscriptionGrammaticalityFieldDisplay']
      ['morpheme_break',                'oldMorphemeBreakFieldDisplay']
      ['morpheme_gloss',                'oldMorphemeGlossFieldDisplay']
    ]

    # OLD generic display for an OLD linguistic form field (attribute/value
    # pair). If OLD form fields were their own views, this would be the base
    # class. The higher-level functions "inherit" from this by passing a novel
    # `contentCallback`, which controls how the field (i.e., attribute value)
    # is displayed. This function is called from within a template; thus the
    # `context` parameter is the context, i.e., `@` within the template,
    # which has the attributes of `@model.toJSON()`.
    oldGenericIGTFieldDisplay: (attribute, context, contentCallback) =>
      tooltip = tooltips("old.formAttributes.#{attribute}")(
        language: 'eng'
        value: context[attribute]
      )
      "<div class='form-#{@utils.snake2hyphen attribute}'
        #{@displayNoneStyle context[attribute]}>
        <div class='form-igt-data-label dative-tooltip'
          title=\"#{tooltip}\"
          >#{@utils.snake2regular attribute}</div>
        <div class='form-igt-data-content'>#{contentCallback attribute, context}</div>
      </div>"

    # Phonetic Transcription Field.
    oldPhoneticTranscriptionFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @utils.encloseIfNotAlready context[attribute], '[', ']'
      @oldGenericIGTFieldDisplay attribute, context, contentCallback

    # Transcription with Grammaticality Field.
    oldTranscriptionGrammaticalityFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        "<span class='grammaticality'>#{context.grammaticality}</span>
          #{context[attribute]}"
      @oldGenericIGTFieldDisplay attribute, context, contentCallback

    # Morpheme Break Field.
    oldMorphemeBreakFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @utils.encloseIfNotAlready context[attribute], '/', '/'
      @oldGenericIGTFieldDisplay attribute, context, contentCallback

    # Morpheme Gloss Field.
    # (Potential TODO: small-caps-ify all-caps morpheme abbreviations)
    oldMorphemeGlossFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        context[attribute]
      @oldGenericIGTFieldDisplay attribute, context, contentCallback

    # Secondary OLD Form Attributes.
    # This array defines the order of how the secondary attributes are
    # displayed. The first item in the 2-tuple is the attribute name; the
    # second item is the method used to generate its HTML display.
    oldFormSecondaryAttributes: [
      ['syntactic_category_string', 'oldStringFieldDisplay']
      ['break_gloss_category',      'oldStringFieldDisplay']
      ['comments',                  'oldStringFieldDisplay']
      ['speaker_comments',          'oldStringFieldDisplay']
      ['elicitation_method',        'oldObjectWithNameFieldDisplay']
      ['tags',                      'oldArrayOfObjectsWithNameFieldDisplay']
      ['syntactic_category',        'oldObjectWithNameFieldDisplay']
      ['date_elicited',             'oldDateFieldDisplay']
      ['speaker',                   'oldPersonFieldDisplay']
      ['elicitor',                  'oldPersonFieldDisplay']
      ['enterer',                   'oldPersonFieldDisplay']
      ['datetime_entered',          'oldDateFieldDisplay']
      ['modifier',                  'oldPersonFieldDisplay']
      ['datetime_modified',         'oldDateFieldDisplay']
      ['verifier',                  'oldPersonFieldDisplay']
      ['source',                    'oldSourceFieldDisplay']
      ['files',                     'oldArrayOfObjectsWithNameFieldDisplay']
      ['collections',               'oldArrayOfObjectsWithTitleFieldDisplay']
      ['syntax',                    'oldStringFieldDisplay']
      ['semantics',                 'oldStringFieldDisplay']
      ['status',                    'oldStringFieldDisplay']
      ['UUID',                      'oldStringFieldDisplay']
      ['id',                        'oldStringFieldDisplay']
    ]

    # OLD generic display for an OLD linguistic secondary data form field
    # (attribute/value pair). If OLD form fields were their own views, this
    # would be the base class. The higher-level functions "inherit" from this
    # by passing a novel `contentCallback`, which controls how the field (i.e.,
    # attribute value) is displayed. This function is called from within a
    # template; thus the `context` parameter is the context, i.e., `@` within
    # the template, which has the attributes of `@model.toJSON()`.
    oldGenericSecondaryDataFieldDisplay: (attribute, context, contentCallback) =>
      tooltip = tooltips("old.formAttributes.#{attribute}")(
        language: 'eng'
        value: context[attribute]
      )
      "<div class='form-#{@utils.snake2hyphen attribute}'
        #{@displayNoneStyle context[attribute]}>
        <div class='form-secondary-data-label dative-tooltip'
          title=\"#{tooltip}\"
          >#{@utils.snake2regular attribute}</div>
        <div class='form-secondary-data-content'>#{contentCallback attribute, context}</div>
      </div>"

    # String Field.
    oldStringFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) -> context[attribute]
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Object-with-a-`name` Field
    oldObjectWithNameFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        try
          context[attribute].name
        catch
          ''
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Source Field.
    oldSourceFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        try
          source = context[attribute]
          "#{source.author} (#{source.year})"
        catch
          ''
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Array-of-objects-with-`name`-attributes Field.
    oldArrayOfObjectsWithNameFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        result = []
        for object in context[attribute]
          try
            result.push "<div class='form-#{attribute[...-1]}'>#{object.name}</div>"
        result.join '\n'
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Array-of-objects-with-`title`-attributes Field.
    oldArrayOfObjectsWithTitleFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        result = []
        for object in context[attribute]
          try
            result.push "<div class='form-#{attribute[...-1]}'>#{object.title}</div>"
        result.join '\n'
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Date(time) Field.
    oldDateFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) => @utils.timeSince context[attribute]
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Person Field.
    oldPersonFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) ->
        person = context[attribute]
        if person
          firstName = person.first_name or ''
          lastName = person.last_name or ''
          "#{firstName} #{lastName}".trim()
        else
          ''
      @oldGenericSecondaryDataFieldDisplay attribute, context, contentCallback


    ############################################################################
    # FieldDB-specific template helpers
    ############################################################################

    # The following methods are all responsible for writing FieldDB field
    # labels and values to the DOM.

    # IGT FieldDB Form Attributes.
    # This array defines the "IGT" attributes of a FieldDB form (along with
    # their order). These are those that will be aligned into columns of one
    # word each. This array should be made user-configurable at some point.

    fieldDBFormIGTAttributes: [
      ['utterance', 'fieldDBUtteranceJudgementFieldDisplay']
      ['morphemes', 'fieldDBMorphemesFieldDisplay']
      ['gloss',     'fieldDBGlossFieldDisplay']
    ]

    # FieldDB generic display for a FieldDB linguistic form field
    # (attribute/value # pair). If FieldDB form fields were their own views,
    # this would be the base class. The higher-level functions "inherit" from
    # this by passing a novel `contentCallback`, which controls how the field
    # (i.e., attribute value) is displayed. This function is called from within
    # a template; thus the `context` parameter is the context, i.e., `@` within
    # the template, which has the attributes of `@model.toJSON()`.
    fieldDBGenericIGTFieldDisplay: (attribute, context, contentCallback) =>
      value = @getFieldDBDatumValue context, attribute
      tooltip = @getFieldDBTooltip attribute, context
      "<div class='form-#{@utils.camel2hyphen attribute}'
        #{@displayNoneStyle value}>
        <div class='form-igt-data-label dative-tooltip'
          title=\"#{tooltip}\"
          >#{@utils.camel2regular attribute}</div>
        <div class='form-igt-data-content'>#{contentCallback attribute, context}</div>
      </div>"

    getFieldDBTooltip: (attribute, context) =>
      help = @getFieldDBDatumHelp context, attribute
      if help and attribute isnt 'dateElicited'
        help
      else
        value = @getFieldDBDatumValue context, attribute
        tooltips("fieldDB.formAttributes.#{attribute}")(
          language: 'eng'
          value: value
        )

    # Get the value corresponding to the passed-in FieldDB `attribute`.
    # `datumObject` is `@model.toJSON()`. This abstracts the idiosyncratic
    # way in which fieldDB datum data are stored.
    # WARN: this is potentially problematic since it makes assumptions about
    # an attribute's location based on its form/name...
    # NOTE: `getDatumFieldValue` and `getSessionFieldValue` are defined in
    # views/base.coffee because `form-add-widget.coffee` uses them too.
    getFieldDBDatumValue: (datumObject, attribute) ->
      if attribute in @fieldDBDirectAttributes
        datumObject[attribute]
      else if attribute in @fieldDBSessionFieldAttributes
        @getSessionFieldValue datumObject.session.sessionFields, attribute
      else if attribute is 'modifiedByUser'
        modifiedByUser = @getDatumField datumObject.datumFields, attribute
        try
          modifiedByUser.users
        catch
          modifiedByUser
      else
        @getDatumFieldValue datumObject.datumFields, attribute

    getFieldDBDatumHelp: (datumObject, attribute) ->
      try
        if attribute in @fieldDBSessionFieldAttributes
          @getSessionFieldHelp datumObject.session.sessionFields, attribute
        else
          @getDatumFieldHelp datumObject.datumFields, attribute
      catch
        null

    # TODO/QUESTION: should the `title` of the session that a datum/form
    # belongs to be displayed among the form's secondary attributes?

    # FieldDB direct attributes, i.e., those not in `datumFields` or `session`.
    # NOTE: these are only the attributes that I consider to be relevant to the
    # form display.
    fieldDBDirectAttributes: [
      'id'
      'audioVideo'
      'comments'
      'dateEntered'
      'dateModified'
      'datumTags'
      'images'
      'timestamp'
    ]

    # Attributes of a FieldDB datum's `session.sessionFields` array.
    # NOTE: these are only the attributes that I consider to be relevant to the
    # form display.
    fieldDBSessionFieldAttributes: [
      'goal'
      'consultants'
      'dialect'
      'language'
      'dateElicited'
      'user'
      'dateSEntered'
    ]

    # Utterance with Judgement Field.
    fieldDBUtteranceJudgementFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        value = @getFieldDBDatumValue context, attribute
        judgement = @fieldDBJudgementConverter @getFieldDBDatumValue(context, 'judgement')
        "<span class='judgement'>#{judgement}</span>#{value}"
      @fieldDBGenericIGTFieldDisplay attribute, context, contentCallback

    # Morphemes Field.
    fieldDBMorphemesFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        value = @getFieldDBDatumValue context, attribute
        @utils.encloseIfNotAlready value, '/', '/'
      @fieldDBGenericIGTFieldDisplay attribute, context, contentCallback

    # Gloss Field.
    # (Potential TODO: small-caps-ify all-caps morpheme abbreviations)
    fieldDBGlossFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @getFieldDBDatumValue context, attribute
      @fieldDBGenericIGTFieldDisplay attribute, context, contentCallback

    # Secondary FieldDB Form Attributes.
    # This array defines the order of how the secondary attributes are
    # displayed. The first item in the 2-tuple is the attribute name; the
    # second item is the method used to generate its HTML display.
    # QUESTION: @cesine: how is the elicitor of a FieldDB datum/session
    # documented?
    fieldDBFormSecondaryAttributes: [
      ['syntacticCategory',  'fieldDBStringFieldDisplay']
      ['comments',           'fieldDBCommentsFieldDisplay'] # direct Datum attribute
      ['tags',               'fieldDBStringFieldDisplay']
      ['dateElicited',       'fieldDBDateFieldDisplay']     # from `sessionFields`
      ['language',           'fieldDBStringFieldDisplay']   # from `sessionFields`
      ['dialect',            'fieldDBStringFieldDisplay']   # from `sessionFields`
      ['consultants',        'fieldDBStringFieldDisplay']   # from `sessionFields`
      ['enteredByUser',      'fieldDBStringFieldDisplay']
      ['dateEntered',        'fieldDBDateFieldDisplay']     # direct Datum attribute
      ['modifiedByUser',     'fieldDBModifiersArrayFieldDisplay']
      ['dateModified',       'fieldDBDateFieldDisplay']     # direct Datum attribute
      ['syntacticTreeLatex', 'fieldDBStringFieldDisplay']
      ['validationStatus',   'fieldDBStringFieldDisplay']
    ]

    # Return a list of the Datum attributes that will not be displayed by
    # looping through the defined secondary and IGT attributes.
    fieldDBAlreadyDisplayedFields: =>
      secondaryAttributes = (a for [a, d] in @fieldDBFormSecondaryAttributes)
      igtAttributes = (a for [a, d] in @fieldDBFormIGTAttributes)
      ['judgement', 'translation'].concat secondaryAttributes, igtAttributes

    # FieldDB generic display for a FieldDB linguistic secondary data form
    # field. If FieldDB form fields were their own views, this would be the base
    # class. The higher-level functions "inherit" from this # by passing a
    # novel `contentCallback`, which controls how the field (i.e., attribute
    # value) is displayed. This function is called from within a template; thus
    # the `context` parameter is the context, i.e., `@` within the template,
    # which has the attributes of `@model.toJSON()`.
    fieldDBGenericSecondaryDataFieldDisplay: (attribute, context, contentCallback) =>
      value = @getFieldDBDatumValue context, attribute
      tooltip = @getFieldDBTooltip attribute, context
      "<div class='form-#{@utils.camel2hyphen attribute}'
        #{@fieldDBDisplayNoneStyle attribute, value}>
        <div class='form-secondary-data-label dative-tooltip'
          title=\"#{tooltip}\"
          >#{@utils.camel2regular attribute}</div>
        <div class='form-secondary-data-content'>#{contentCallback attribute, context}</div>
      </div>"

    # Wrap the default `displayNoneStyle` method: account for FieldDB idiosyncracy
    # where we don't want to display `modifiedByUser` if it contains only one
    # element.
    fieldDBDisplayNoneStyle: (attribute, value) =>
      if attribute is 'modifiedByUser'
        try
          if value.length <= 1
            @styleDisplayNone
          else
            ''
        catch
          @styleDisplayNone
      else
        @displayNoneStyle value

    # String Field.
    fieldDBStringFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @getFieldDBDatumValue context, attribute
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Schema: {text: '', username: '', timestamp: ''}
    fieldDBCommentsFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        comments = @getFieldDBDatumValue context, attribute
        result = []
        for comment in comments.reverse()
          result.push "<div class='form-fielddb-comment'>
            <span class='form-fielddb-comment-text'>#{comment.text}</span>
            (By <span class='form-fielddb-comment-username'
            >#{comment.username}</span>
            <span class='form-fielddb-comment-timestamp dative-tooltip'
            title='This comment was made on
            #{@utils.humanDatetime(new Date(comment.timestamp))}'
            >#{@utils.timeSince(new Date(comment.timestamp))})</span>
            </div>"
        result.join '\n'
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # Date(time) Field.
    fieldDBDateFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        @utils.timeSince @getFieldDBDatumValue(context, attribute)
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

    # An array of user objects each of which has four attributes:
    #   appVersion: "2.38.16.07.59ss Fri Jan 16 08:02:30 EST 2015"
    #   gravatar: "5b7145b0f10f7c09be842e9e4e58826d"
    #   timestamp: 1423667274803
    #   username: "jdunham"
    # NOTE: @cesine: I ignore the first modifier object because it is different
    # than the rest: it has no timestamp. I think it just redundantly records
    # the enterer.
    fieldDBModifiersArrayFieldDisplay: (attribute, context) =>
      contentCallback = (attribute, context) =>
        modifiers = @getFieldDBDatumValue context, attribute
        result = []
        try
          for modifier in modifiers.reverse()[...-1]
            timestampSpan = ''
            if modifier.timestamp
              timestampSpan = "<span class='form-fielddb-modifier-timestamp
                dative-tooltip' title='This modification was made on
                #{@utils.humanDatetime(new Date(modifier.timestamp))}'
                >#{@utils.timeSince(new Date(modifier.timestamp))}</span>"
            result.push "<div class='form-fielddb-modifier'>
                <span class='form-fielddb-modifier-username'
                  >#{modifier.username}</span> #{timestampSpan}</div>"
          result.join '\n'
        catch
          ''
      @fieldDBGenericSecondaryDataFieldDisplay attribute, context, contentCallback

