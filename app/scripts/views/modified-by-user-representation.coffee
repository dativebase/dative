define [
  './representation'
  './../templates/modified-by-user-representation'
], (RepresentationView, modifiedByUserRepresentationTemplate) ->

  # Modified By User Representation View
  # ------------------------------------
  #
  # A view for the representation of a single FieldDB modifiedByUser (i.e., an
  # object with two relevant attributes: `username` and `timestamp`).

  class ModifiedByUserRepresentationView extends RepresentationView

    template: modifiedByUserRepresentationTemplate

