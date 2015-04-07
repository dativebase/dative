define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Source Field Display View
  # -------------------------
  #
  # A view for displaying a source field, i.e., a textual source such as a
  # dictionary or a linguistics paper.

  class SourceFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      try
        context.value = "#{context.value.author} (#{context.value.year})"
      catch
        context.value = ''
      context

