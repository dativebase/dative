define [
  './resource'
  './../utils/bibtex'
], (ResourceModel, BibTeXUtils) ->

  # Source Model
  # ------------
  #
  # A Backbone model for Dative sources.

  class SourceModel extends ResourceModel

    resourceName: 'source'

    # Note that `crossref_source` is not in here because the user does not
    # specify it directly. It is by selecting a `crossref` value that the
    # `crossref_source` relational value gets specified server-side.
    manyToOneAttributes: [
      'file'
    ]

    ############################################################################
    # Source Schema
    ############################################################################

    defaults: ->

      file: null             # a reference to a file (e.g., a pdf) for this source

      crossref_source: null  # a reference to another source model for
                             # cross-referencing, cf. the BibTeX spec

      crossref: ''           # The `key` value of another source to be
                             # cross-referenced. Any attribute values that
                             # are missing from the source model are inherited
                             # from the source cross-referenced via the
                             # cross-reference attribute. Maximum length is
                             # 1000 characters. Note: OLD will return an error
                             # if a non-existent key value is supplied here.
                             # QUESTION: how do `crossref_source` and
                             # `crossref` interact? I think that specifying the
                             # latter determines the former.

      type: ''               # the BibTeX entry type, e.g., “article”,
                             # “book”, etc. A valid type value is
                             # obligatory for all source models. The chosen
                             # type value will determine which other attributes
                             # must also possess non-empty values. See p. 391
                             # of Dunham 2014.

      key: ''                # the BibTeX key, i.e., the unique string used to
                             # unambiguously identify a source. E.g., “chomsky57”.

      address: ''            # Usually the address of the publisher or other
                             # type of institution. Maximum length is 1000
                             # characters.

      annote: ''             # An annotation. It is not used by the standard
                             # bibliography styles, but may be used by others
                             # that produce an annotated bibliography.

      author: ''             # The name(s) of the author(s), in the format
                             # described in Kopka and Daly (2004). There are
                             # two basic formats: (1) Given Names Surname and
                             # (2) Surname, Given Names. For multiple authors,
                             # use the formats just specified and separate each
                             # such formatted name by the word “and”.
                             # Maximum length is 255 characters.

      booktitle: ''          # Title of a book, part of which is being cited.
                             # See Kopka and Daly (2004) for details on how to
                             # type titles. For book entries, use the title
                             # field instead. Maximum length is 255 characters.

      chapter: ''            # A chapter (or section or whatever) number.
                             # Maximum length is 255 characters.

      edition: ''            # The edition of a book—for example,
                             # “Second”. This should be an ordinal, and
                             # should have the first letter capitalized, as
                             # shown here; the standard styles convert to lower
                             # case when necessary. Maximum length is 255
                             # characters.

      editor: ''             # Name(s) of editor(s), typed as indicated in
                             # Kopka and Daly (2004). At its most basic, this
                             # means either as Given Names Surname or Surname,
                             # Given Names and using “and” to separate
                             # multiple editor names. If there is also a value
                             # for the author attribute, then the editor
                             # attribute gives the editor of the book or
                             # collection in which the reference appears.
                             # Maximum length is 255 characters.

      howpublished: ''       # How something has been published. The first word
                             # should be capitalized. Maximum length is 255
                             # characters.

      institution: ''        # The sponsoring institution of a technical
                             # report. Maximum length is 255 characters.

      journal: ''            # A journal name. Abbreviations are provided for
                             # many journals. Maximum length is 255 characters.

      key_field: ''          # Used for alphabetizing, cross referencing, and
                             # creating a label when the author information is
                             # missing. This field should not be confused with
                             # the source’s key attribute. Maximum length is
                             # 255 characters.

      month: ''              # The month in which the work was published or,
                             # for an unpublished work, in which it was
                             # written. Maximum length is 100 characters.

      note: ''               # Any additional information that can help the
                             # reader. The first word should be capitalized.
                             # Maximum length is 1000 characters.

      number: ''             # The number of a journal, magazine, technical
                             # report, or of a work in a series. An issue of a
                             # journal or magazine is usually identified by its
                             # volume and number; the organization that issues
                             # a technical report usually gives it a number;
                             # and sometimes books are given numbers in a named
                             # series. Maximum length is 100 characters.

      organization: ''       # The organization that sponsors a conference or
                             # that publishes a manual. Maximum length is 255
                             # characters.

      pages: ''              # One or more page numbers or range of numbers,
                             # such as 42–111 or 7,41,73– 97 or 43+ (the
                             # “+” in this last example indicates pages
                             # following that don’t form a simple range).
                             # Maximum length is 100 characters.

      publisher: ''          # The publisher’s name. Maximum length is 255
                             # characters.

      school: ''             # The name of the school where a thesis was
                             # written. Maximum length is 255 characters.

      series: ''             # The name of a series or set of books. When
                             # citing an entire book, the title attribute gives
                             # its title and an optional series attribute gives
                             # the name of a series or multi-volume set in
                             # which the book is published. Maximum length is
                             # 255 characters.

      title: ''              # The work’s title, typed as explained in Kopka
                             # and Daly (2004). Maximum length is 255
                             # characters.

      type_field: ''         # The type of a technical report—for example,
                             # “Research Note”. Maximum length is 255
                             # characters.

      url: ''                # The universal resource locator for online
                             # documents; this is not standard but supplied by
                             # more modern bibliography styles. Maximum length
                             # is 1000 characters.

      volume: ''             # The volume of a journal or multi-volume book.
                             # Maximum length is 100 characters.

      year: ''               # The year of publication or, for an unpublished
                             # work, the year it was written. Generally it
                             # should consist of four numerals, such as 1984.

      affiliation: ''        # The author’s affiliation. Maximum length is
                             # 255 characters.

      abstract: ''           # An abstract of the work. Maximum length is 1000
                             # characters.

      contents: ''           # A table of contents. Maximum length is 255
                             # characters.

      copyright: ''          # Copyright information. Maximum length is 255
                             # characters.

      ISBN: ''               # The International Standard Book Number. Maximum
                             # length is 20 characters.

      ISSN: ''               # The International Standard Serial Number. Used
                             # to identify a journal. Maximum length is 20
                             # characters.

      keywords: ''           # Key words used for searching or possibly for
                             # annotation. Maximum length is 255 characters.

      language: ''           # The language the document is in. Maximum length
                             # is 255 characters.

      location: ''           # A location associated with the entry, such as
                             # the city in which a conference took place.
                             # Maximum length is 255 characters.

      LCCN: ''               # The Library of Congress Call Number. Maximum
                             # length is 20 characters.

      mrnumber: ''           # The Mathematical Reviews number. Maximum length
                             # is 25 characters.

      price: ''              # The price of the document. Maximum length is 100
                             # characters.

      size: ''               # The physical dimensions of a work. Maximum
                             # length is 255 characters.


      id: null               # <int> relational id
      datetime_modified: ""  # <string>  (datetime resource was last modified,
                             # format and construction same as
                             # `datetime_entered`.)

    editableAttributes: [
      'file'
      'crossref_source'
      'crossref'
      'type'
      'key'
      'address'
      'annote'
      'author'
      'booktitle'
      'chapter'
      'edition'
      'editor'
      'howpublished'
      'institution'
      'journal'
      'key_field'
      'month'
      'note'
      'number'
      'organization'
      'pages'
      'publisher'
      'school'
      'series'
      'title'
      'type_field'
      'url'
      'volume'
      'year'
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

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        when 'key' then @validBibTeXKey
        when 'type' then @validBibTeXType
        else null

    validBibTeXKey: (value) ->
      regex = /^([-!$%^&*()_+|~=`{}\[\]:";'<>?.\/]|[a-zA-Z0-9])+$/
      if regex.test value
        null
      else
        'Source keys can only contain letters, numerals and symbols (except the
          comma)'

    # Given the BibTeX entry type in `value`, make sure that all of the required
    # fields (as specified in `@entryTypes[value].required` are valuated.
    validBibTeXType: (value) ->
      if not value then return 'You must select a type for this source'
      invalid = false

      # BibTeX type determines required fields. Get them here.
      [requiredFields, disjunctivelyRequiredFields, msg] =
        @parseRequirements value

      # Here we set error messages on zero or more attributes, given the typed
      # requirements of BibTeX.
      requiredFieldsValues =
        (@getRequiredValue(rf) for rf in requiredFields)
      requiredFieldsValues = (rf for rf in requiredFieldsValues when rf)
      if requiredFieldsValues.length isnt requiredFields.length
        invalid = true
      else
        for dr in disjunctivelyRequiredFields
          drValues = (@getRequiredValue(rf) for rf in dr)
          drValues = (rf for rf in drValues when rf)
          if drValues.length is 0 then invalid = true
      if invalid
        errorObject = type: msg
        for field in requiredFields
          if not @getRequiredValue(field)
            errorObject[field] = "Please enter a value"
        for fieldsArray in disjunctivelyRequiredFields
          values = (@getRequiredValue(f) for f in fieldsArray)
          values = (v for v in values when v)
          if values.length is 0
            for field in fieldsArray
              errorObject[field] = "Please enter a value for
                #{@coordinate fieldsArray, 'or'}"
        errorObject
      else
        null

    getRequiredValue: (requiredField) ->
        """Try to get a value for the required field `requiredField`; if it's
        not there, try the cross-referenced source model.
        """
        val = @get requiredField
        if val
          val
        else
          crossReferencedSource = @get 'crossref_source'
          if crossReferencedSource
            val = crossReferencedSource[requiredField]
            if val then val else null
          else
            null

    coordinate: (array, coordinator='and') ->
      if array.length > 1
        "#{array[...-1].join ', '} #{coordinator} #{array[array.length - 1]}"
      else if array.length is 1
        array[0]
      else
        ''

    # Given a BibTeX `type` value, return a 3-tuple array consisting of the
    # required fields, the disjunctively required fields, and a text message
    # declaring those requirements.
    parseRequirements: (typeValue) ->

      conjugateValues = (requiredFields) ->
        if requiredFields.length > 1 then 'values' else 'a value'

      required = @entryTypes[typeValue].required
      requiredFields = (r for r in required when @utils.type(r) is 'string')
      disjunctivelyRequiredFields =
        (r for r in required when @utils.type(r) is 'array')

      msg = "Sources of type #{typeValue} require #{conjugateValues requiredFields}
        for #{@coordinate requiredFields}"
      if disjunctivelyRequiredFields.length > 0
        tmp = ("at least one of #{@coordinate dr}" for dr in disjunctivelyRequiredFields)
        msg = "#{msg} as well as a value for #{@coordinate tmp}"

      [requiredFields, disjunctivelyRequiredFields, "#{msg}."]

    # Maps each BibTeX `type` value to the array of other attributes that must
    # (`required`) and may (`optional`) be valuated for that type.
    entryTypes:

      article:
        required: ['author', 'title', 'journal', 'year']
        optional: ['volume', 'number', 'pages', 'month', 'note']

      book:
        required: [['author', 'editor'], 'title', 'publisher', 'year']
        optional: [['volume', 'number'], 'series', 'address', 'edition',
          'month', 'note']

      booklet:
        required: ['title']
        optional: ['author', 'howpublished', 'address', 'month', 'year', 'note']

      conference:
        required: ['author', 'title', 'booktitle', 'year']
        optional: ['editor', ['volume', 'number'], 'series', 'pages',
          'address', 'month', 'organization', 'publisher', 'note']

      inbook:
        required: [['author', 'editor'], 'title', ['chapter', 'pages'],
          'publisher', 'year']
        optional: [['volume', 'number'], 'series', 'type', 'address',
          'edition', 'month', 'note']

      incollection:
        required: ['author', 'title', 'booktitle', 'publisher', 'year']
        optional: ['editor', ['volume', 'number'], 'series', 'type', 'chapter',
          'pages', 'address', 'edition', 'month', 'note']

      inproceedings:
        required: ['author', 'title', 'booktitle', 'year']
        optional: ['editor', ['volume', 'number'], 'series', 'pages',
          'address', 'month', 'organization', 'publisher', 'note']

      manual:
        required: ['title']
        optional: ['author', 'organization', 'address', 'edition', 'month',
          'year', 'note']

      mastersthesis:
        required: ['author', 'title', 'school', 'year']
        optional: ['type', 'address', 'month', 'note']

      misc:
        required: []
        optional: ['author', 'title', 'howpublished', 'month', 'year', 'note']

      phdthesis:
        required: ['author', 'title', 'school', 'year']
        optional: ['type', 'address', 'month', 'note']

      proceedings:
        required: ['title', 'year']
        optional: ['editor', ['volume', 'number'], 'series', 'address',
          'month', 'publisher', 'organization', 'note']

      techreport:
        required: ['author', 'title', 'institution', 'year']
        optional: ['type', 'number', 'address', 'month', 'note']

      unpublished:
        required: ['author', 'title', 'note']
        optional: ['month', 'year']


    ############################################################################
    # String Conveniences
    ############################################################################
    #
    # Call these methods to get string-like representations of the source;
    # needed because BibTeX ain't simple.

    getAuthor: -> BibTeXUtils.getAuthor @attributes

    getYear: -> BibTeXUtils.getYear @attributes

    # Get `attr` from this source's `crossref_source` value.
    getCrossrefAttr: (attr) ->
      crossref = @get 'crossref_source'
      if crossref then crossref[attr] else null

    # Return a string like "Chomsky and Halle (1968)"
    # Setting `crossref` to `false` will result in `crossref` not being used
    # for empty value.
    getAuthorYear: (crossref=true) ->
      author = @get 'author'
      if (not author) and crossref then author = @getCrossrefAttr 'author'
      authorCitation = BibTeXUtils.getNameInCitationForm author
      year = @get 'year'
      if (not year) and crossref then year = @getCrossrefAttr 'year'
      "#{authorCitation} (#{year})"

    # Return a string like "Chomsky and Halle (1968)", using editor names if
    # authors are unavailable.
    getAuthorEditorYear: (crossref=true) ->
      name = @getAuthorEditor crossref
      nameCitation = BibTeXUtils.getNameInCitationForm name
      "#{nameCitation} (#{@get 'year'})"

    # Get author, else crossref.author, else editor, else crossref.editor
    getAuthorEditor: (crossref=true) ->
      name = @get 'author'
      if (not name) and crossref then name = @getCrossrefAttr 'author'
      if not name then name = @get 'editor'
      if (not name) and crossref then name = @getCrossrefAttr 'editor'
      name

    # Try to return a string like "Chomsky and Halle (1968)", but replace
    # either the author/editor or the year with filler text, if needed.
    getAuthorEditorYearDefaults: (crossref=true) ->
      auth = @getAuthorEditor crossref
      if auth
        auth = BibTeXUtils.getNameInCitationForm auth
      else
        auth = 'no author'
      year = @get 'year'
      if (not year) and crossref then year = @getCrossrefAttr 'year'
      yr = if year then year else 'no year'
      "#{auth} (#{yr})"

