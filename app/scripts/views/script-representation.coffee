define [
  './representation'
  './../templates/script-representation'
], (RepresentationView, scriptRepresentationTemplate) ->

  # Script Representation View
  # --------------------------
  #
  # A view for the representation of a script, e.g., for a phonology.

  class ScriptRepresentationView extends RepresentationView

    template: scriptRepresentationTemplate

