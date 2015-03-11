define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Object with Name Field Display View
  # -----------------------------------
  #
  # A view for displaying a field whose value is an object with a `name`
  # attribute.

  class ObjectWithNameFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      try
        context.value = context.value.name
      catch
        context.value = ''
      context

