define [
  './controls'
  './test-validation-control'
  './character-names-control'
], (ControlsView, TestValidationControlView, CharacterNamesControlView) ->


  class TestMorphemeBreakValidationControlView extends TestValidationControlView

    targetField: 'morpheme break'
    textareaLabel: 'Morpheme break validation test'


  class TestNarrowPhoneticValidationControlView extends TestValidationControlView

    targetField: 'narrow phonetic transcription'
    textareaLabel: 'Narrow phonetic transcription validation test'


  class TestBroadPhoneticValidationControlView extends TestValidationControlView

    targetField: 'broad phonetic transcription'
    textareaLabel: 'Phonetic transcription validation test'


  # Collection Controls View
  # ------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a collection resource.

  class CollectionControlsView extends ControlsView

    actionViewClasses: [
      TestValidationControlView
      TestNarrowPhoneticValidationControlView
      TestBroadPhoneticValidationControlView
      TestMorphemeBreakValidationControlView
      CharacterNamesControlView
    ]

