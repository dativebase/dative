define [
  './exporter'
  './../models/source'
], (ExporterView, SourceModel) ->

  # Exporter that exports collections of resources to LaTeX source files. It's
  # actually XeLaTeX because converting arbitrary Unicode characters to LaTeX
  # commands is impractical.

  class ExporterLaTeXView extends ExporterView

    title: -> 'LaTeX'

    description: ->
      if @model
        "LaTeX export of #{@model.resourceName} #{@model.id}."
      else if @collection
        if @collection.corpus
          "LaTeX export of the forms in corpus “#{@collection.corpus.name}.”"
        else if @collection.search
          console.log @collection.search
          if @collection.search.name
            "LaTeX export of the #{@collection.resourceNamePlural} in search
              “#{@collection.search.name}.”"
          else
            "LaTeX export of the #{@collection.resourceNamePlural} that match
              the search currently being browsed."
        else
          "LaTeX export of all #{@collection.resourceNamePlural} in the
            database."
      else
        'LaTeX export of a collection of resources'

    # This array should contain 'collection' or 'model' or '*'
    exportTypes: -> ['*']

    exportResources: -> ['form', 'collection']

    updateControls: ->
      @clearControls()
      @selectAllButton()

    hasSettings: -> true

    # Render the settings interface. Lets user choose between "comma" and
    # "newline" delimited formats.
    renderSettings: ->
      @$('.exporter-settings').html(
        "<ul>
          <li>
            <label class='exporter-settings-label'
              for='igt_package'>IGT package</label>
            <select name='igt_package'>
              <option value='expex'>ExPex</option>
              <option value='covington'>Covington</option>
            </select>
          </li>
        </ul>"
      )
      x = =>
        @$('select[name=igt_package]').selectmenu width: 'auto'
      setTimeout x, 5 # Delay is a hack to make in-dialog selectmenus work.

    # Return the user-specified export settings. If the <select> value is
    # 'newline' it means ids should be 'form[1]\nform[2]\n' etc. Otherwise,
    # they are comma-delimited.
    getSettings: ->
      igtPackage: @$('select[name=igt_package]').val()
      secondaryData: true # TODO: get option from user
      reference: true # TODO: get option from user

    # The OLD API gives us the forms of the collection (in
    # `{forms: [{...}, ...], ...}`) when we make a GET request to
    # /oldcollections/<collection_id>
    fetchCollectionForms: ->
      @model.fetchResource @model.id


    listenToEvents: ->
      super
      if @model
        @listenTo @model, 'fetchCollectionStart', @fetchResourceCollectionStart
        @listenTo @model, 'fetchCollectionEnd', @fetchResourceCollectionEnd
        @listenTo @model, 'fetchCollectionFail', @fetchResourceCollectionFail
        @listenTo @model, 'fetchCollectionSuccess',
          @fetchCollectionSuccess

    export: ->
      settings = @getSettings()
      @$(@contentContainerSelector()).slideDown()
      $contentContainer = @$ @contentSelector()
      if @model
        if @model.resourceName is 'form'
          content = "<pre>#{@getModelAsLaTeX(@model.attributes,
            settings).trim()}</pre>"
        else
          msg = "fetching the forms in collection #{@model.id} ..."
          @fetchCollectionForms()
          content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
      else if @collection
        if @collection.corpus
          msg = "fetching a corpus of #{@collection.resourceNamePlural} ..."
        else if @collection.search
          msg = "fetching a search over #{@collection.resourceNamePlural} ..."
        else
          msg = "fetching all #{@collection.resourceNamePlural} ..."
        @fetchResourceCollection true
        content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

    # Return a title and author for the collection.
    getTitleAuthor: ->
      if @collection
        if @collection.corpus
          title = "Corpus “#{@collection.corpus.name}”"
          author = "#{@collection.corpus.enterer.first_name}
            #{@collection.corpus.enterer.last_name}"
        else if @collection.search
          if @collection.search.name
            title = "Results of Search “#{@collection.search.name}”"
            author = "#{search.enterer.first_name}
              #{search.enterer.last_name}"
          else
            title = 'Search Results'
            author = 'no author'
        else
          title = 'All Forms'
          author = 'no author'
      else
        title = 'No Title'
        author = 'no author'
      [title, author]

    # We have retrieved an array of form objects in (`collectionArray`). We
    # convert this to a string of LaTeX and put this string in the exporter
    # interface along with a "Select All" button.
    fetchResourceCollectionSuccess: (collectionArray) ->
      super
      $contentContainer = @$ @contentSelector()
      if collectionArray.length is 0
        msg = "Sorry, there are no #{@collection.resourceNamePlural} to export"
        $contentContainer.html msg
        return
      [title, author] = @getTitleAuthor()
      latex = @getCollectionAsLaTeX collectionArray, title, author
      $contentContainer.html "<pre>#{latex}</pre>"
      @selectAllButton()

    # A particular OLD collection resource has been fetched. We export it as a
    # sequence of form references. Converting reStructuredText or Markdown to
    # LaTeX needs to be done server-side. (OLD TODO.)
    fetchCollectionSuccess: (collection) ->
      $contentContainer = @$ @contentSelector()
      regex = /form\[(\d+)\]/g
      forms = []
      while match = regex.exec(collection.contents)
        id = parseInt(match[1])
        form = _.findWhere(collection.forms, {id: id})
        if form
          forms.push form
      title = collection.title or "Collection #{collection.id}"
      author = @getAuthorFromCollection collection
      latex = @getCollectionAsLaTeX forms, title, author
      $contentContainer.html "<pre>#{latex}</pre>"
      @selectAllButton()

    getAuthorFromCollection: (collection) ->
      if collection.elicitor
        author = collection.elicitor
      else if collection.enterer
        author = collection.enterer
      else
        author = null
      if author
        "#{author.first_name} #{author.last_name}"
      else
        'author unknown'

    # Convert a collection of forms (i.e., an array of forms) to a string of
    # LaTeX.
    getCollectionAsLaTeX: (forms, title='no title', author='author unknown') ->
      @errors = false
      settings = @getSettings()
      result = [@xelatexPreamble(settings.igtPackage, title, author)]
      for formObject in forms
        result.push @getModelAsLaTeX(formObject, settings)
      result.push "\n\n\\end{document}\n"
      if @errors then Backbone.trigger 'csvExportError'
      result.join '\n'

    getModelAsLaTeX: (model, settings) ->
      if settings.igtPackage is 'expex'
        @expexFormFormatter model, settings
      else
        @covingtonFormFormatter model, settings

    # Escape the 10 LaTeX special characters.
    escapeLaTeX: (string) ->
      try
        string
          .replace /\\/g, '\\textbackslash'
          .replace /{/g, '\\{'
          .replace /}/g, '\\}'
          .replace /textbackslash/g, 'textbackslash{}'
          .replace /&/g, '\\&'
          .replace /%/g, '\\%'
          .replace /\$/g, '\\$'
          .replace /#/g, '\\#'
          .replace /_/g, '\\_'
          .replace /~/g, '\\textasciitilde{}'
          .replace /\^/g, '\\textasciicircum{}'
      catch error
        string

    # ExPex allows a trailing citation which comes on the same line as the last
    # free translation. I use this to cite the form, prefering speaker and date
    # elicited, then source. The OLD id is always included.
    expexTrailingCitation: (form) ->
      trailingCitation = ['\\trailingcitation{(']
      if form.speaker
        speaker = ["#{@escapeLaTeX(form.speaker.first_name[0].toUpperCase())}\
          #{@escapeLaTeX(form.speaker.last_name[0].toUpperCase())}"]
        if form.date_elicited
          speaker.push ", #{@escapeLaTeX @utils.humanDate(form.date_elicited)}"
        trailingCitation = trailingCitation.concat speaker
        trailingCitation.push ", OLD ID: #{form.id}"
      else if form.source
        sourceModel = new SourceModel(form.source)
        sourceString = sourceModel.getAuthorYear()
        trailingCitation.push(@escapeLaTeX sourceString)
        trailingCitation.push ", OLD ID: #{form.id}"
      else
        trailingCitation.push "OLD ID: #{form.id}"
      trailingCitation.push ')}'
      trailingCitation.join ''

    # Return a XeLaTeX representation of a form using the ExPex package to put
    # the words into IGT formatted examples.
    expexFormFormatter: (form, settings) ->
      result = ['\n\n\\ex\n']
      if not form
        result.push '\tWARNING: BAD FORM REFERENCE'
      else
        trailingCitation = @expexTrailingCitation(form)
        transcriptionAttributes = ['transcription',
          'narrow_phonetic_transcription', 'phonetic_transcription',
          'morpheme_break']
        while transcriptionAttributes.length > 0
          attr = transcriptionAttributes.shift()
          val = form[attr]
          if val
            result = result.concat([
              "\t\\begingl"
              "\n\t\t\\gla #{@escapeLaTeX form.grammaticality}\
                #{@escapeLaTeX val}//"
            ])
            break
        for attr in transcriptionAttributes
          val = form[attr]
          if val
            result.push "\n\t\t\\glb #{@escapeLaTeX val}//"
        if form.morpheme_gloss
          result.push "\n\t\t\\glb #{@escapeLaTeX form.morpheme_gloss}//"
        translations = []
        for translation in form.translations
          translations.push("#{@escapeLaTeX translation.grammaticality}\
            `#{@escapeLaTeX translation.transcription}'")
        translations = translations.join '\\\\\n\t\t'
        result = result.concat([
          "\n\t\t\\glft #{translations}#{trailingCitation}//"
          '\n\t\\endgl'
        ])
        if settings.secondaryData
          result = result.concat([
            '\n',
            @xelatexSecondaryData(form, settings.reference)
          ])
        result.push '\n\\xe'
        result.join ''

    # Return a XeLaTeX representation of a form using the Covington package to
    # put the words into IGT formatted examples.
    # TODO: I was originally using h.capsToLatexSmallCaps to convert uppercase
    # glosses to LaTeX smallcaps (\textsc{}), but the Aboriginal Serif font was
    # not rendering the smallcaps, so I removed the function.  If I can figure
    # out how to use XeLaTeX with a font that will render NAPA symbols AND
    # make smallcaps, then the function should be reinstated...
    covingtonFormFormatter: (form, settings) ->
      result = ['\n\n\\begin{examples}\n']
      if not form
        result.push('\t\\item WARNING: BAD FORM REFERENCE')
      else
        # If the Form has a morphological analysis, use Covington for IGT
        translations = []
        for translation in form.translations
          translations.push("#{@escapeLaTeX translation.grammaticality}\
            `#{@escapeLaTeX translation.transcription}'")
        translations = translations.join '\\\\ \n\t\t'
        if form.morpheme_break and form.morpheme_gloss
          result = result.concat([
            '\t\\item'
            "\n\t\t\\glll #{@escapeLaTeX form.grammaticality}\
              #{@escapeLaTeX form.transcription}"
            "\n\t\t#{@escapeLaTeX form.morpheme_break}"
            "\n\t\t#{@escapeLaTeX form.morpheme_gloss}"
            "\n\t\t\\glt #{translations}"
            '\n\t\t\\glend'
          ])
        # If no morphological analysis, just put transcr and gloss(es) on separate lines
        else
          result = result.concat([
            '\t\\item'
            "\n\t\t#{@escapeLaTeX form.grammaticality}\
              #{@escapeLaTeX form.transcription} \\\\"
            "\n\t\t#{translations}"
          ])
        if settings.secondaryData
          result = result.concat([
            '\n',
            @xelatexSecondaryData(form, settings.reference)
          ])
      result.push('\n\\end{examples}')
      result.join ''

    # Return the form's comments, speaker comments and a reference as a LaTeX
    # itemized list. Reference is 'x(yz)' where 'x' is the speaker's initials,
    # 'y' is the date elicited and 'z' is the id of the Form. If reference is
    # false, no reference to the form is added.
    xelatexSecondaryData: (form, reference=true) ->
      result = ['\t\\begin{itemize}']
      if form.comments
        result.push "\n\t\t\\item #{@escapeLaTeX form.comments}"
      if form.speaker_comments
        result.push "\n\t\t\\item #{@escapeLaTeX form.speaker_comments}"
      if form.context
        result.push "\n\t\t\\item #{@escapeLaTeX form.context}"
      if reference
        if form.speaker
          speaker = "#{@escapeLaTeX form.speaker.first_name[0].toUpperCase()}\
            #{@escapeLaTeX form.speaker.last_name[0].toUpperCase()} "
        else
          speaker = ''
        if form.date_elicited
          dateElicited = "#{@escapeLaTeX @utils.humanDate(
            form.date_elicited)}, "
        else
          dateElicited = ''
        if form.speaker
          result.push "\n\t\t\\item #{speaker}(#{dateElicited}OLD ID:
            #{form.id})"
        else if form.source
          sourceModel = new SourceModel(form.source)
          sourceString = sourceModel.getAuthorYear()
          result.push "\n\t\t\\item #{sourceString}, OLD ID: #{form.id}"
        else
          result.push "\n\t\t\\item (#{dateElicited}OLD ID: #{form.id})"
      result.push '\n\t\\end{itemize}'
      if result.length > 2 then return result.join('')
      ''

    xelatexPreamble: (igtPackage, title, author) ->

      """
        %!TEX TS-program = xelatex
        %!TEX encoding = UTF-8 Unicode

        \\documentclass[12pt]{article}

        \\usepackage{fontspec}
        % Font selection for XeLaTeX; see fontspec.pdf for documentation

        \\defaultfontfeatures{Mapping=tex-text}
        % to support TeX conventions like ``---''

        \\usepackage{xunicode}
        % Unicode support for LaTeX character names (accents, European chars, etc)

        \\usepackage{xltxtra}
        % Extra customizations for XeLaTeX

        \\setmainfont{Charis SIL}
        % set the main body font -- if you don't have Charis SIL, then install it or
        % install and use Doulos SIL, or Aboriginal Sans, etc.

        \\usepackage{#{igtPackage}}
        \\title{#{title}}
        \\author{#{author}}
        %\\date{}

        \\begin{document}
        \\maketitle

      """

