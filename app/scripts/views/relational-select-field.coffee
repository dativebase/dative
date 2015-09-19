define [
  './select-field'
  './../utils/globals'
], (SelectFieldView, globals) ->

  # Relational Select(menu) Field View
  # ----------------------------------
  #
  # A specialized SelectFieldView for OLD relational fields.

  class RelationalSelectFieldView extends SelectFieldView

    listenToEvents: ->
      super

      # If our options change in `globals` we refresh ourselves so that that
      # change is reflected in the selectmenu. Note that
      # `globals.get(@optionsAttribute).data` is the same array referenced by
      # `@options`; this is why we don't need to update `@options` manually.
      @listenTo globals, "change:#{@optionsAttribute}", @refresh

    getValueFromDOM: ->
      @getValueFromRelationalIdFromDOM super

