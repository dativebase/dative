define [
  './controls'
  './count-search-results-control'
  './browse-search-results-control'
], (ControlsView, CountSearchResultsControlView,
  BrowseSearchResultsControlView) ->

  # Subcorpus Controls View
  # ----------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a subcorpus resource.

  class SubcorpusControlsView extends ControlsView

    actionViewClasses: [
      BrowseSearchResultsControlView
      CountSearchResultsControlView
    ]

