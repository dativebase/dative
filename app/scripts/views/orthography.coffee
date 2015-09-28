define [
  './resource'
  './orthography-add-widget'
  './date-field-display'
  './field-display'
  './unicode-string-field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, OrthographyAddWidgetView, DateFieldDisplayView,
  FieldDisplay, UnicodeStringFieldDisplayView, EntererFieldDisplayView,
  ModifierFieldDisplayView) ->

  class OrthographyOrthographyFieldDisplay extends UnicodeStringFieldDisplayView

    # We alter `context` so that `context.valueFormatter` is a function that
    # returns an inventory as a list of links that, on mouseover, indicate the
    # Unicode code point and Unicode name of the characters in the graph.
    getContext: ->
      context = super
      context.valueFormatter = (value) =>
        result = []
        graphs = (g.trim() for g in value.split(','))
        for graph in graphs
          if @utils.startsWith(graph, '[') then graph = graph[1...]
          if @utils.endsWith(graph, ']') then graph = graph[...(graph.length - 1)]
          result.push @unicodeLink(graph)
        result.join ', '
      context

  # Orthography View
  # ----------------
  #
  # For displaying individual orthographies.

  class OrthographyView extends ResourceView

    resourceName: 'orthography'

    resourceAddWidgetView: OrthographyAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'orthography'
      'lowercase'
      'initial_glottal_stops'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      orthography: OrthographyOrthographyFieldDisplay

