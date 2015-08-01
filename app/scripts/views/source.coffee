define [
  './resource'
  './source-add-widget'
  './date-field-display'
], (ResourceView, SourceAddWidgetView, DateFieldDisplayView) ->

  # Source View
  # -----------
  #
  # For displaying individual sources.

  class SourceView extends ResourceView

    resourceName: 'source'

    resourceAddWidgetView: SourceAddWidgetView

    getHeaderTitle: ->
      switch @model.get('type')
        when 'article' then @authorYear()
        when 'book' then @authorEditorYear()
        when 'booklet' then @titleRequired()
        when 'conference' then @authorYear()
        when 'inbook' then @authorEditorYear()
        when 'incollection' then @authorYear()
        when 'inproceedings' then @authorYear()
        when 'manual' then @titleRequired()
        when 'mastersthesis' then @authorYear()
        when 'misc' then @misc()
        when 'phdthesis' then @authorYear()
        when 'proceedings' then @titleYear()
        when 'techreport' then @authorYear()
        when 'unpublished' then @titleRequired()
        else @authorYear()

    # Return a string like "Chomsky and Halle (1968)"
    authorYear: ->
      author = @model.get 'author'
      authorCitation = @getNameInCitationForm author
      "#{authorCitation} (#{@model.get 'year'})"

    # Return a string like "Chomsky and Halle (1968)", using editor names if
    # authors are unavailable.
    authorEditorYear: ->
      if @model.get 'author'
        name = @model.get 'author'
      else
        name = @model.get 'editor'
      nameCitation = @getNameInCitationForm name
      "#{nameCitation} (#{@model.get 'year'})"

    # Try to return a string like "Chomsky and Halle (1968)", but just return
    # the title if author or year are missing.
    titleRequired: ->
      if @model.get('author') and @model.get('year')
        @authorYear()
      else
        @model.get 'title'

    # Return a string like "The Sound Pattern of English (1968)".
    titleYear: -> "#{@model.get 'title'} (#{@model.get 'year'})"

    # Try to return a string like "Chomsky and Halle (1968)", but replace
    # either the author or the year with filler text, if needed.
    misc: ->
      author = @model.get 'author'
      if author
        auth = @getNameInCitationForm author
      else
        auth = 'no author'
      year = @model.get 'year'
      yr = if year then year else 'no year'
      "#{auth} (#{yr})"

    # Return a name-type BibTeX value (e.g., 'author', or 'editor') as a
    # conjunction (with commas) of last names, e.g., "Mozart, Brahms and von
    # Beethoven".
    getNameInCitationForm: (name) ->
      parsedName = @parseBibTeXName name
      if parsedName
        @getLastNames parsedName
      else
        name

    # Given a parsed BibTeX name (an array of arrays of arrays), return a
    # string of conjoined last names, e.g., "Smith, Yang, and Moore".
    getLastNames: (parsedName) ->
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
    parseBibTeXName: (input) ->
      try
        @parseBibTeXName_ input
      catch
        null

    parseBibTeXName_: (input) ->
      cleanPart = (part) ->
        if part[0] is '{' and part[part.length - 1] is '}'
          part[1...-1]
        else
          part
      output = []
      names = input.split ' and '
      r = /\{[^\}\{]+\}|[^ ,]+|,/g
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

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView

    # Attributes that are always displayed.
    primaryAttributes: [
      'key'
      'type'
      'file'
      'crossref_source'
      'crossref'
      'author'
      'editor'
      'year'
      'journal'
      'title'
      'booktitle'
      'chapter'
      'pages'
      'publisher'
      'school'
      'institution'
      'note'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'volume'
      'number'
      'month'
      'series'
      'address'
      'edition'
      'annote'
      'howpublished'
      'key_field'
      'organization'
      'type_field'
      'url'
      'affiliation'
      'abstract'
      'contents'
      'copyright'
      'ISBN'
      'ISSN'
      'keywords'
      'language'
      'location'
      'LCCN'
      'mrnumber'
      'price'
      'size'
    ]

