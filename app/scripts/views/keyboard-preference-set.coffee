define [
  './resource'
  './keyboard'
  './keyboard-preference-set-add-widget'
  './related-resource-field-display'
  './related-resource-representation'
  './../models/keyboard'
  './../collections/keyboards'
], (ResourceView, KeyboardView, KeyboardPreferenceSetAddWidgetView,
  RelatedResourceFieldDisplayView, RelatedResourceRepresentationView,
  KeyboardModel, KeyboardsCollection) ->

  class MyRelatedResourceRepresentationView extends RelatedResourceRepresentationView

    getEmptyValue: -> 'not specified'


  class TranscriptionKeyboardFieldDisplayView extends RelatedResourceFieldDisplayView

    relatedResourceRepresentationViewClass: MyRelatedResourceRepresentationView
    resourceName: 'keyboard'
    attributeName: 'transcription_keyboard'
    resourceModelClass: KeyboardModel
    resourcesCollectionClass: KeyboardsCollection
    resourceViewClass: KeyboardView
    shouldBeHidden: -> false
    nullResourceAsString: (resource) -> 'not specified'


  class SystemWideKeyboardFieldDisplayView extends TranscriptionKeyboardFieldDisplayView

    attributeName: 'system_wide_keyboard'


  class PhoneticTranscriptionKeyboardFieldDisplayView extends TranscriptionKeyboardFieldDisplayView

    attributeName: 'phonetic_transcription_keyboard'


  class NarrowPhoneticTranscriptionKeyboardFieldDisplayView extends TranscriptionKeyboardFieldDisplayView

    attributeName: 'narrow_phonetic_transcription_keyboard'


  class MorphemeBreakKeyboardFieldDisplayView extends TranscriptionKeyboardFieldDisplayView

    attributeName: 'morpheme_break_keyboard'


  # Keyboard Preference Set View
  # ----------------------------
  #
  # For displaying a "keyboard preference set", i.e., a set of assignments of
  # keyboards to specific form fields. These are stored client-side and are
  # user-specific. This allows the user to always use a specific keyboard when
  # entering data into a particular form field.

  class KeyboardPreferenceSetView extends ResourceView

    initialize: (options={}) ->
      options.labelsAlwaysVisible = true
      super options

    resourceName: 'keyboardPreferenceSet'

    resourceAddWidgetView: KeyboardPreferenceSetAddWidgetView

    getHeaderTitle: -> 'Your Keyboard Preferences'

    excludedActions: [
      'history'
      'controls'
      'data'
      'settings'
      'delete'
      'duplicate'
      'export'
    ]

    # Attributes that are always displayed.
    primaryAttributes: [
      'system_wide_keyboard'
      'transcription_keyboard'
      'phonetic_transcription_keyboard'
      'narrow_phonetic_transcription_keyboard'
      'morpheme_break_keyboard'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: []

    # Map attribute names to display view class names.
    attribute2displayView:
      system_wide_keyboard: SystemWideKeyboardFieldDisplayView
      transcription_keyboard: TranscriptionKeyboardFieldDisplayView
      phonetic_transcription_keyboard:
        PhoneticTranscriptionKeyboardFieldDisplayView
      narrow_phonetic_transcription_keyboard:
        NarrowPhoneticTranscriptionKeyboardFieldDisplayView
      morpheme_break_keyboard: MorphemeBreakKeyboardFieldDisplayView

