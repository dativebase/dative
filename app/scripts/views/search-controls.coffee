define [
  './controls'
  './count-search-results-control'
  './browse-search-results-control'
], (ControlsView, CountSearchResultsControlView,
  BrowseSearchResultsControlView) ->

  # Search Controls View
  # ----------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a search resource. These actions are
  #
  # 1.

  class SearchControlsView extends ControlsView

    actionViewClasses: [
      BrowseSearchResultsControlView
      CountSearchResultsControlView
    ]

