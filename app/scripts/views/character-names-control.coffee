define [
  './base'
  './../utils/globals'
  './../templates/textarea-control'
  'autosize'
], (BaseView, globals, textareaButtonControlTemplate) ->

  # Character Names Control View
  # ----------------------------
  #
  # View for a control for allowing users to type in text and tell them the
  # Unicode code points and names of the characters they are entering.

  class CharacterNamesControlView extends BaseView

    # Change this in subclasses to something that corresponds to `@targetField`.
    textareaLabel: 'Unicode character names and codes'

    template: textareaButtonControlTemplate
    className: 'character-names-control-view control-view dative-widget-center'

    events:
      'input textarea[name=character-names]':   'getCharacterNames'

    # Create an HTML table listing the characters, their code points, and their
    # names.
    getCharacterNames: ->
      val = @$('textarea[name=character-names]').val().normalize 'NFD'
      if val
        result = [
          "<div class='Scrollable character-names-table-container
            dative-shadowed-widget ui-corner-all'>"
          "<table class='character-names-table'>"
          "  <thead>"
          "    <tr>"
          "      <th>Character</th>"
          "      <th>Unicode code point</th>"
          "      <th>Name</th>"
          "    </tr>"
          "  </thead>"
          "  <tbody>"
        ]
        for grapheme in val
          codePoint = @utils.decimal2hex(grapheme.charCodeAt(0)).toUpperCase()
          try
            name = globals.unicodeCharMap[codePoint] or 'Name unknown'
          catch
            name = 'Name unknown'
          result.push "    <tr>\
            \n      <td>#{grapheme}</td>\
            \n      <td>U+#{codePoint}</td>\
            \n      <td>#{name}</td>\
            \n    </tr>"
        result.push "  <tbody>\n</table>\n</div>"
        @$(".#{@resultsContainerClass}").html result.join('\n')
        @$('div.character-names-table-container')
          .css "border-color", @constructor.jQueryUIColors().defBo
      else
        @$(".#{@resultsContainerClass}").html ''

    # Write the initial HTML to the page.
    html: ->
      title = 'Enter text here to see the Unicode code points and names of the
        characters.'
      context =
        textareaLabel: @textareaLabel
        textareaLabelTitle: title
        textareaName: 'character-names'
        textareaTitle: title
        resultsContainerClass: @resultsContainerClass
      @$el.html @template(context)

    resultsContainerClass: 'character-names-results'

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    guify: ->
      @tooltipify()
      @bordercolorify()
      @autosize()

    tooltipify: ->
      @$('.dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo

    autosize: -> @$('textarea').autosize append: false

    disableTestValidationInput: ->
      @$('textarea[name=character-names]').attr 'disabled', true

    enableTestValidationInput: ->
      @$('textarea[name=character-names]').attr 'disabled', false

