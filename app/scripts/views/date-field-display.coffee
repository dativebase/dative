define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Date Field Display View
  # -----------------------
  #
  # A view for displaying a date field.

  class DateFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      try
        context.value = @utils.timeSince context.value
      catch
        context.value = ''
      context

