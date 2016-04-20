define [
  './resource-add-widget'
  './keyboard-select-via-search-field'
  './../models/keyboard-preference-set'
], (ResourceAddWidgetView, KeyboardSelectViaSearchFieldView,
  KeyboardPreferenceSetModel) ->

  # Keyboard Preference Set Add Widget View
  # ---------------------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # keyboard preference set or updating an existing one.

  ##############################################################################
  # Keyboard Preference Set Add Widget
  ##############################################################################

  class KeyboardPreferenceSetAddWidgetView extends ResourceAddWidgetView

    resourceName: 'keyboardPreferenceSet'
    resourceModel: KeyboardPreferenceSetModel

    attribute2fieldView:
      system_wide_keyboard: KeyboardSelectViaSearchFieldView
      transcription_keyboard: KeyboardSelectViaSearchFieldView
      phonetic_transcription_keyboard: KeyboardSelectViaSearchFieldView
      narrow_phonetic_transcription_keyboard: KeyboardSelectViaSearchFieldView
      morpheme_break_keyboard: KeyboardSelectViaSearchFieldView

    primaryAttributes: [
      'system_wide_keyboard'
      'transcription_keyboard'
      'phonetic_transcription_keyboard'
      'narrow_phonetic_transcription_keyboard'
      'morpheme_break_keyboard'
    ]

    # Tell the Help dialog to open itself and search "keyboard preferences".
    openResourceAddHelp: (event) ->
      if event then @stopEvent event
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "keyboard preferences"
        scrollToIndex: 1
      )

