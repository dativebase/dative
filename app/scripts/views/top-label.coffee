define [
  './label'
  './../templates/top-label'
], (LabelView, topLabelTemplate) ->

  # Top Label View
  # --------------
  #
  # A view for field labels that are above the thing they label.

  class TopLabelView extends LabelView

    initialize: (@context) ->
      super
      @template = topLabelTemplate

