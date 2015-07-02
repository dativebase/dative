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
        context.value = @humanFileSize context.value, true
      catch
        context.value = ''
      context

    shouldBeHidden: ->
      response = super
      if response is false and @context.initialValue is null
        response = true
      response

    # From http://stackoverflow.com/questions/10420352/converting-file-size-in-bytes-to-human-readable
    humanFileSize: (bytes, si) ->
      thresh = if si then 1000 else 1024
      if Math.abs(bytes) < thresh then return "#{bytes} B"
      if si
        units = ['kB','MB','GB','TB','PB','EB','ZB','YB']
      else
        units = ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB']
      u = -1
      loop
        bytes /= thresh
        ++u
        if not ((Math.abs(bytes) >= thresh) and (u < (units.length - 1)))
          break
      "#{bytes.toFixed(1)} #{units[u]}"

