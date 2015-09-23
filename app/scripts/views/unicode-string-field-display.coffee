define [
  './field-display'
  './../utils/globals'
], (FieldDisplayView, globals) ->

  # Unicode String Field Display View
  # ---------------------------------
  #
  # A field display view for attributes that are strings of Unicode characters
  # where the code points and canonical names of the characters should be
  # viewable to the user.

  class UnicodeStringFieldDisplayView extends FieldDisplayView

    # Return the decimal number `decimal` has a hex string with left-padding 0s
    # to minimum length 4.
    decimal2hex: (decimal) ->
      hex = Number(decimal).toString 16
      if hex.length < 4
        "#{Array(5 - hex.length).join '0'}#{hex}"
      else
        hex

    # `graph` is a string. Return it as a link with a tooltip that lists the
    # Unicode code points of the characters in `graph` and their (Unicode)
    # names.
    unicodeLink: (graph) ->
      meta = []
      # WARNING: we may want to normalize further upstream in the client-side
      # processing of user input!
      graph = graph.normalize 'NFD'
      for grapheme in graph
        codePoint = @decimal2hex(grapheme.charCodeAt(0)).toUpperCase()
        try
          name = globals.unicodeCharMap[codePoint] or 'Name unknown'
        catch
          name = 'Name unknown'
        meta.push "U+#{codePoint} (#{name})"
      "<a
        href='javascript:;'
        class='dative-tooltip undecorated-link'
        title='#{meta.join ', '}'
        >#{graph}</a>"

