define ['./select-field'], (SelectFieldView) ->

  # Relational Select(menu) Field View
  # ----------------------------------
  #
  # A specialized SelectFieldView for OLD relational fields.

  class RelationalSelectFieldView extends SelectFieldView

    getValueFromDOM: ->
      @getValueFromRelationalIdFromDOM super

