define [
  './settings'
  './morphology-select-via-search-field'
  './phonology-select-via-search-field'
  './../models/form'
], (SettingsView, MorphologySelectViaSearchFieldView,
  PhonologySelectViaSearchFieldView, FormModel) ->

  # Form Settings View
  # ------------------
  #
  # View for a widget for viewing and modifying the settings of form resources
  # in the system.
  #
  # Form resources can use morphological parsers, phonologies, and/or
  # morphologies for the following tasks:
  #
  # i. suggest morpheme break and morpheme gloss values based on user input
  #    into the transcription, phonetic transcription, and/or narrow phonetic
  #    transcription fields.
  #
  # ii. suggest transcription, phonetic transcription, and/or narrow phonetic
  #     transcription values based on user input into the morpheme break field
  #     (and possibly also the morpheme gloss field).
  #
  # iii. alert the user to whether the morpheme break and morpheme gloss values
  #      are compatible with (i.e., recognized by) a given morphology.
  #
  # iv. (do orthography conversion?)

  class FormSettingsView extends SettingsView

    initialize: (options) ->
      super options
      @parserSettingsVisible = false
      @events['click button.toggle-parser-settings'] =
        'toggleParserSettings'
      @listenForFSTResourceSelectInterfaceClicks()
      @selectInterfaceViewsInitialized = false
      @selectInterfaceViewsRendered = false

    # TODO: put 'morphologicalParser' in here ...
    # transcription-parser-select-interface-container
    # phonetic-transcription-parser-select-interface-container
    # narrow-phonetic-transcription-parser-select-interface-container
    # transcription-phonologizer-phonology-select-interface-container
    # phonetic-transcription-phonologizer-phonology-select-interface-container
    # narrow-phonetic-transcription-phonologizer-phonology-select-interface-container
    # recognizer-morphology-select-interface-container
    tasks: ->
      [
          fstResourceName: 'phonology'
          selectInterfaceClass: PhonologySelectViaSearchFieldView
          target: 'transcription'
          source: ['morphemeBreak', 'morphemeGloss', 'syntacticCategoryString']
          containerClass: 'transcription-phonologizer-phonology-select-interface-\
            container'

        ,
          fstResourceName: 'phonology'
          selectInterfaceClass: PhonologySelectViaSearchFieldView
          target: 'phoneticTranscription'
          source: ['morphemeBreak', 'morphemeGloss', 'syntacticCategoryString']
          containerClass: 'phonetic-transcription-phonologizer-phonology-select-\
            interface-container'
        ,
          fstResourceName: 'phonology'
          selectInterfaceClass: PhonologySelectViaSearchFieldView
          target: 'narrowPhoneticTranscription'
          source: ['morphemeBreak', 'morphemeGloss', 'syntacticCategoryString']
          containerClass: 'narrow-phonetic-transcription-phonologizer-phonology-\
            select-interface-container'
        ,
          fstResourceName: 'morphology'
          selectInterfaceClass: MorphologySelectViaSearchFieldView
          target: null
          source: ['morphemeBreak', 'morphemeGloss', 'syntacticCategoryString']
          containerClass: 'recognizer-morphology-select-interface-container'
      ]

    getSearchFieldAttribute: (vector) ->
      if vector.target
        "#{vector.target}\
          #{@utils.capitalize vector.fstResourceName}SearchField]"
      else
        "#{vector.fstResourceName}SearchField]"

    initializeFSTResourceSelectInterfaceViews: ->
      dummyFormModel = new FormModel()
      for taskVector in @tasks()
        params =
          resource: @resourceNamePlural
          attribute: taskVector.fstResourceName
          model: dummyFormModel
          options: {}
          addUpdateType: 'add'
        @[@getSearchFieldAttribute(taskVector)] =
          new taskVector.selectInterfaceClass params

    renderFSTResourceSelectInterfaceViews: ->
      for taskVector in @tasks()
        resourceSearchField = @[@getSearchFieldAttribute(taskVector)]
        @$(".#{taskVector.containerClass}").first()
          .html resourceSearchField.render().el
        @rendered resourceSearchField

    initializeFSTResourceSelectInterfaceViewsCheck: ->
      if not @selectInterfaceViewsInitialized
        @initializeFSTResourceSelectInterfaceViews()
        @selectInterfaceViewsInitialized = true

    renderFSTResourceSelectInterfaceViewsCheck: ->
      if not @selectInterfaceViewsRendered
        @renderFSTResourceSelectInterfaceViews()
        @selectInterfaceViewsRendered = true

    listenForFSTResourceSelectInterfaceClicks: ->

      @events['click button.transcription-parser-select-button'] =
        'openTranscriptionParserSelectInterface'
      @events['click button.phonetic-transcription-parser-select-button'] =
        'openPhoneticTranscriptionParserSelectInterface'
      @events['click button.narrow-phonetic-transcription-parser-select-button'] =
        'openNarrowPhoneticTranscriptionParserSelectInterface'

      @events['click button.transcription-phonologizer-phonology-select-button'] =
        'openTranscriptionPhonologizerPhonologySelectInterface'
      @events['click button.phonetic-transcription-phonologizer-phonology-select-button'] =
        'openPhoneticTranscriptionPhonologizerPhonologySelectInterface'
      @events['click button.narrow-phonetic-transcription-phonologizer-phonology-select-button'] =
        'openNarrowPhoneticTranscriptionPhonologizerPhonologySelectInterface'

      @events['click button.recognizer-morphology-select-button'] =
        'openRecognizerMorphologySelectInterface'

    getFieldCategoryNames: -> [
      'igt'
      'translation'
      'secondary'
      'readonly'
    ]

    getHeaderTitle: -> 'Form Settings'

    render: ->
      super
      @parserSettingsVisibility()
      @

    guify: ->
      super

    parserSettingsVisibility: ->
      if @parserSettingsVisible
        @$('.parser-settings').show()
      else
        @$('.parser-settings').hide()
      @setParserSettingsToggleButtonState()

    toggleParserSettings: ->
      if @parserSettingsVisible
        @parserSettingsVisible = false
        @$('.parser-settings').slideUp()
      else
        @parserSettingsVisible = true
        @$('.parser-settings').slideDown()
      @setParserSettingsToggleButtonState()

    setParserSettingsToggleButtonState: ->
      if @parserSettingsVisible
        @$('button.toggle-parser-settings i')
          .removeClass 'fa-caret-right'
          .addClass 'fa-caret-down'
      else
        @$('button.toggle-parser-settings i')
          .removeClass 'fa-caret-down'
          .addClass 'fa-caret-right'

    openTranscriptionParserSelectInterface: ->
      @openParserSelectInterface()

    openPhoneticTranscriptionParserSelectInterface: ->
      @openParserSelectInterface 'phoneticTranscription'

    openNarrowPhoneticTranscriptionParserSelectInterface: ->
      @openParserSelectInterface 'narrowPhoneticTranscription'

    openTranscriptionPhonologizerPhonologySelectInterface: ->
      @openPhonologySelectInterface()

    openPhoneticTranscriptionPhonologizerPhonologySelectInterface: ->
      @openPhonologySelectInterface 'phoneticTranscription'

    openNarrowPhoneticTranscriptionPhonologizerPhonologySelectInterface: ->
      @openPhonologySelectInterface 'narrowPhoneticTranscription'

    openRecognizerMorphologySelectInterface: ->
      @openMorphologySelectInterface()

    prep: ->
      @initializeFSTResourceSelectInterfaceViewsCheck()
      @renderFSTResourceSelectInterfaceViewsCheck()

    hideAllFSTSelectInterfaces: ->
      @$('.fst-select-interface-container').hide()

    openParserSelectInterface: (receiver='transcription') ->
      @prep()
      @hideAllFSTSelectInterfaces()
      switch receiver
        when 'transcription'
          @$('.transcription-parser-select-interface-container').slideDown()
        when 'phoneticTranscription'
          @$('.phonetic-transcription-parser-select-interface-container').slideDown()
        when 'narrowPhoneticTranscription'
          @$('.narrow-phonetic-transcription-parser-select-interface-container').slideDown()

    openPhonologySelectInterface: (receiver='transcription') ->
      @prep()
      @hideAllFSTSelectInterfaces()
      switch receiver
        when 'transcription'
          @$('.transcription-phonologizer-phonology-select-interface-container')
            .slideDown()
        when 'phoneticTranscription'
          @$('.phonetic-transcription-phonologizer-phonology-select-interface-container')
            .slideDown()
        when 'narrowPhoneticTranscription'
          @$('.narrow-phonetic-transcription-phonologizer-phonology-select-interface-container')
            .slideDown()

    openMorphologySelectInterface: ->
      @prep()
      @hideAllFSTSelectInterfaces()
      @$('.recognizer-morphology-select-interface-container').slideDown()

