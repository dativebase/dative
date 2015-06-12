define [
  './controls'
  './count-corpus-control'
  './browse-search-results-control'
], (ControlsView, CountCorpusControlView,
  BrowseSearchResultsControlView) ->

  # Subcorpus Controls View
  # ----------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a subcorpus resource.

  class SubcorpusControlsView extends ControlsView

    actionViewClasses: [
      BrowseSearchResultsControlView
      CountCorpusControlView
    ]

