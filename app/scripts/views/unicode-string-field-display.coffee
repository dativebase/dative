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

    # `graph` is a string. Return it as a link with a tooltip that lists the
    # Unicode code points of the characters in `graph` and their (Unicode)
    # names.
    unicodeLink: (graph) ->
      meta = []
      # WARNING: we may want to normalize further upstream in the client-side
      # processing of user input!
      graph = graph.normalize 'NFD'
      for grapheme in graph
        codePoint = @utils.decimal2hex(grapheme.charCodeAt(0)).toUpperCase()
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

