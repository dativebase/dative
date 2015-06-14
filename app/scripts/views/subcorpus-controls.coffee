define [
  './controls'
  './count-corpus-control'
  './browse-corpus-control'
], (ControlsView, CountCorpusControlView,
  BrowseCorpusControlView) ->

  # Subcorpus Controls View
  # -----------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a subcorpus resource.

  class SubcorpusControlsView extends ControlsView

    actionViewClasses: [
      BrowseCorpusControlView
      CountCorpusControlView
    ]

