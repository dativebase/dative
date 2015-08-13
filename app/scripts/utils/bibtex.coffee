define [], ->

  # BibTeX Utilities
  # ----------------
  #
  # Logic for handling sources/bibliographic references in BibTeX format.

  class BibTeXUtils

    # Return a name-type BibTeX value (e.g., 'author', or 'editor') as a
    # conjunction (with commas) of last names, e.g., "Mozart, Brahms and von
    # Beethoven".
    @getNameInCitationForm: (name) ->
      parsedName = @parseBibTeXName name
      if parsedName
        @getLastNames parsedName
      else
        name

    # Given a parsed BibTeX name (an array of arrays of arrays), return a
    # string of conjoined last names, e.g., "Smith, Yang, and Moore".
    @getLastNames: (parsedName) ->
      lastNamesArray = (author[2].join(' ') for author in parsedName)
      switch lastNamesArray.length
        when 1
          lastNamesArray[0]
        when 2
          "#{lastNamesArray[0]} and #{lastNamesArray[1]}"
        else
          "#{lastNamesArray[...-1].join ', '} and
            #{lastNamesArray[lastNamesArray.length - 1]}"

    # Return an array of arrays representing the parse of the BibTeX name.
    # The parse is an array that contains a name-array, one for each name
    # in the name string. Each name-array contains four part-arrays:
    # part-array 1 is for first names, part-array 2 is for "von" names,
    # part-array 3 is for last names, and part-array 4 is for "Jr." names.
    # See http://nwalsh.com/tex/texhelp/bibtx-23.html.
    # Note: this may not work exactly as BibTeX does it, but it should be good
    # enough.
    @parseBibTeXName: (input) ->
      try
        @parseBibTeXName_ input
      catch
        null

    @parseBibTeXName_: (input) ->
      cleanPart = (part) ->
        if part[0] is '{' and part[part.length - 1] is '}'
          part[1...-1]
        else
          part
      output = []
      names = input.split ' and '
      r = ///
        \{[^\{\}]+\} | # sequence of non-braces between braces
        [^\x20,]+ |    # any non-space or non-comma (\x20 is space char)
        ,              # comma
      ///g
      for name in names
        authorOutput = [[], [], [], []]
        parts = name.match r
        commaCount = (p for p in parts when p is ',').length
        switch commaCount
          when 0 # Type 1: "First von Last"
            vonPartSeen = false
            for part, index in parts
              part = cleanPart part
              if index is 0
                authorOutput[0].push part
              else if index is (parts.length - 1)
                authorOutput[2].push part
              else
                if part is part.toLowerCase()
                  vonPartSeen = true
                  authorOutput[1].push part
                else if vonPartSeen
                  authorOutput[2].push part
                else
                  authorOutput[0].push part
          when 1 # Type 2: "von Last, First"
            section = 1
            for part, index in parts
              part = cleanPart part
              if part is ','
                section = 2
              else if section is 1
                if part is part.toLowerCase()
                  authorOutput[1].push part
                else
                  authorOutput[2].push part
              else
                authorOutput[0].push part
          when 2 # Type 3: "von Last, Jr, First"
            section = 1
            for part, index in parts
              part = cleanPart part
              if part is ','
                section += 1
              else if section is 1
                if part is part.toLowerCase()
                  authorOutput[1].push part
                else
                  authorOutput[2].push part
              else if section is 2
                authorOutput[3].push part
              else
                authorOutput[0].push part
          else
            throw "BibTeX name #{input} cannot be parsed"
        output.push authorOutput
      output

    # Return an "author" for supplied source object. We return the author in
    # citation form if there is an author; otherwise we return the editor in
    # citation form or the title or 'no author'.
    @getAuthor: (sourceObject) ->
      if sourceObject.author
        BibTeXUtils.getNameInCitationForm sourceObject.author
      else if sourceObject.editor
        BibTeXUtils.getNameInCitationForm sourceObject.editor
      else if sourceObject.title
        sourceObject.title
      else
        'no author'

    @getYear: (sourceObject) ->
      if sourceObject.year then sourceObject.year else 'no year'

