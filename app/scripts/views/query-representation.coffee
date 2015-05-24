define [
  './representation'
  './../utils/utils'
], (RepresentationView, utils) ->

  # Query Representation View
  # -------------------------
  #
  # A view for the representation of a field whose value is a query over some
  # collection of resources. A "query" here is modelled on an OLD SQL-style
  # query, i.e., essentially an SQL WHERE-clause (with relational/join-related
  # decisions made for you).
  #
  # fe = [object, attribute, relation, value]
  # fe = [object, attribute, relation, value]
  # fe = ['and', [fe1, fe2, fe3, ...]]
  # fe = ['or', [fe1, fe2, fe3, ...]]
  # fe = ['not', fe ]
  #
  # For arrows between things, see http://stackoverflow.com/questions/554167/drawing-arrows-on-an-html-page-to-visualize-semantic-links-between-textual-spans

  class QueryRepresentationView extends RepresentationView

    # Returns an HTML table that displays a Dative/OLD-style query expression
    # as a sideways tree.
    # TODO: this could be made better with SVG arrows (or JSPlumb) but it's
    # fine for now.
    valueFormatter: (value) ->

      # Return a string representation of a simple OLD-style filter expression,
      # i.e., a 4/5-item array like ['Form', 'morpheme_break', '=', 'chien-s']
      # or ['Form', 'enterer', 'last_name', '!=', 'Chomsky']
      getFilterExpressionString = (query) ->
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

      # Return the <table> that displays the Dative/OLD query as a sideways
      # tree. Note: this function calls itself recursively.
      getFilterTable = (query) ->
        if query[0] in ['and', 'or']
          "<table>
            <tr>
              <td class='middle-cell'>#{query[0]}</td>
              <td><div class='scoped-cell'
                >#{(getFilterTable(x) for x in query[1]).join('')}</div></td>
            </tr>
          </table>"
        else if query[0] is 'not'
          "<table>
            <tr>
              <td class='middle-cell'>#{query[0]}</td>
              <td>#{getFilterTable(query[1])}</td>
            </tr>
          </table>"
        else
          "<table>
            <tr>
              <td class='middle-cell'
                >#{getFilterExpressionString query}</td>
              </tr>
            </table>"

      # TODO: we are only displaying the `filter` attribute; there is also an
      # optional `order_by` attribute that should be being displayed too.
      if utils.type(value) is 'array'
        "no query"
      else
        getFilterTable value.filter

