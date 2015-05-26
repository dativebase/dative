define [
  './input'
  './filter-expression'
  './../utils/utils'
  './../templates/div-input'
], (InputView, FilterExpressionView, utils, divInputTemplate) ->

  # Search Input View
  # -----------------
  #
  # A view for a data input field that is a textarea for creating searches.

  class SearchInputView extends InputView

    template: divInputTemplate

    initialize: (@context) ->
      @filterExpressionView = new FilterExpressionView
        model: @context.model
        filterExpression: @context.value.filter
        options: @context.options

    render: ->
      @$el.html @template(@context)
      @filterExpressionView.setElement @$(".#{@context.class}").first()
      @filterExpressionView.render()
      @rendered @filterExpressionView

      #searchHTMLInterface = @getSearchHTMLInterface @context.value
      #@$(".#{@context.class}").html searchHTMLInterface

    # Returns an HTML table that displays a Dative/OLD-style query expression
    # as a sideways tree.
    # TODO: this could be made better with SVG arrows (or JSPlumb) but it's
    # fine for now.
    getSearchHTMLInterface: (value) ->

      # Return a string representation of a simple OLD-style filter expression,
      # i.e., a 4/5-item array like ['Form', 'morpheme_break', '=', 'chien-s']
      # or ['Form', 'enterer', 'last_name', '!=', 'Chomsky']
      getFilterExpressionHTML = (query) ->
        newArray = []
        if query[0] isnt 'Form' then newArray.push query[0]
        if query.length is 4
          newArray.push utils.snake2regular(query[1])
          newArray.push query[2]
          newArray.push JSON.stringify(query[3])
        else
          newArray.push utils.snake2regular(query[1])
          newArray.push utils.snake2regular(query[2])
          newArray.push query[3]
          newArray.push JSON.stringify(query[4])
        newArray.join ' '

      # Return a <select> where the options are '', 'and', 'or', and 'not'.
      getBooleanSelect = (selectedValue) ->
        result = ["<select>"]
        options = [
          ['', '--'],
          ['and', 'and'],
          ['or', 'or'],
          ['not', 'not']
        ]
        for [value, text] in options
          if value is selectedValue
            result.push "<option value='#{value}' selected>#{text}</option>"
          else
            result.push "<option value='#{value}'>#{text}</option>"
        result.push "</select>"
        result.join '\n'

      # Return the <table> that displays the Dative/OLD query as a sideways
      # tree. Note: this function calls itself recursively.
      getFilterTable = (query) ->
        if query[0] in ['and', 'or']
          "<table>
            <tr>
              <td class='middle-cell'>#{getBooleanSelect query[0]}</td>
              <td><div class='scoped-cell'
                >#{(getFilterTable(x) for x in query[1]).join('')}</div></td>
            </tr>
          </table>"
        else if query[0] is 'not'
          "<table>
            <tr>
              <td class='middle-cell'>#{getBooleanSelect query[0]}</td>
              <td>#{getFilterTable(query[1])}</td>
            </tr>
          </table>"
        else
          "<table>
            <tr>
              <td class='middle-cell'
                >#{getFilterExpressionHTML query}</td>
              </tr>
            </table>"

      # TODO: we are only displaying the `filter` attribute; there is also an
      # optional `order_by` attribute that should be being displayed too.
      if utils.type(value) is 'array'
        "no query"
      else
        getFilterTable value.filter

