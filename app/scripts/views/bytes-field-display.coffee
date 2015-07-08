define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Bytes Field Display View
  # ------------------------
  #
  # A view for displaying an integer that represents a quantify of bytes.
  # Returns a string that expresses the byte value in a more human-readable
  # format, i.e., as bytes, kB, MB, or GB.

  class BytesFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      context.initialValue = context.value
      try
        context.value = @utils.humanFileSize context.value, true
      catch
        context.value = ''
      context

    shouldBeHidden: ->
      response = super
      if response is false and @context.initialValue is null
        response = true
      response

