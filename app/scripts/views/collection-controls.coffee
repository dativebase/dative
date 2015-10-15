define [
  './controls'
  './display-collection-forms-control'
  './display-collection-files-control'
], (ControlsView, DisplayCollectionFormsControlView,
  DisplayCollectionFilesControlView) ->

  # Collection Controls View
  # ------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a collection resource.

  class CollectionControlsView extends ControlsView

    actionViewClasses: [
      DisplayCollectionFormsControlView
      DisplayCollectionFilesControlView
    ]


