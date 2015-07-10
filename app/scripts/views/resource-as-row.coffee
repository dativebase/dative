define [
  './base'
  './resource'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/resource-as-row'
], (BaseView, ResourceView, globals, tooltips, resourceAsRowTemplate) ->

  # Resource-as-Row View
  # --------------------
  #
  # For displaying individual resources as rows; i.e., essentially treating the
  # resource as an array of string values that could be displayed in a
  # 2-dimensional matrix, i.e., a table.

  class ResourceAsRowView extends BaseView

    # Override these in sub-classes.
    resourceName: 'resource'

    # This is the regular resource view class; it is used when the "view"
    # button is clicked.
    resourceViewClass: ResourceView

    # Override this in sub-classes in order to control the left-to-right order
    # of attributes in the view display, and which attributes are displayed.
    orderedAttributes: []

    template: resourceAsRowTemplate
    tagName: 'div'
    #className: 'resource-as-row-row dative-shadowed-widget ui-corner-all'
    className: 'resource-as-row-row'

    # Since this will be called from within templates, the `=>` is necessary.
    resourceNameHumanReadable: =>
      @utils.camel2regular @resourceName

    initialize: (options) ->
      @isHeaderRow = options.isHeaderRow or false
      @query = options.query or null
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural
      @activeServerType = @getActiveServerType()
      @addUpdateType = @getUpdateViewType()

    getUpdateViewType: -> if @model.get('id') then 'update' else 'add'

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    html: ->
      @$el.html @template(@getContext())

    getContext: ->
      model: @getModelAsScalarHighlighted()
      activeServerType: @activeServerType
      addUpdateType: @addUpdateType
      resourceName: @resourceName
      resourceNameHumanReadable: @resourceNameHumanReadable
      isHeaderRow: @isHeaderRow

    events:
      'click .select': 'selectResource'
      'click .view': 'viewResource'

    selectResource: (event) ->
      @stopEvent event
      @trigger 'selectMe', @

    viewResource: (event) ->
      @stopEvent event
      Backbone.trigger 'showResourceModelInDialog', @model, 'FileView'

    guify: ->
      @$('button').button()
      @$('.dative-tooltip').tooltip()

    # Return the model scalarized and with its matches (relqtive to the
    # query/search) highlighted.
    getModelAsScalarHighlighted: ->
      modelAsScalar = @getModelAsScalar()
      modelHighlighted = @highlightModel modelAsScalar
      modelHighlighted

    # An array of subarrays, where each subarray is an OLD-style filter
    # expression.
    patterns: []

    # Highlight the values of the model, given `@query`, if it is non-null.
    # TODO/NOTE: this should probably be done prior to "scalarization" since the
    # current approach will result in improper highlighting since attribute
    # values may be merged into a single string via `scalarTransform`.
    highlightModel: (modelAsScalar) ->
      if @query
        @patterns = [] # patterns to highlight
        @getPatterns @query.filter
        patternsObject = @getPatternsObject @patterns, true
        for attr, val of modelAsScalar
          regex = patternsObject[attr]
          if regex
            val = String val
            modelAsScalar[attr] = val.replace(regex, (a, b) ->
              "<span class='ui-state-highlight ui-corner-all'>#{b}</span>")
        modelAsScalar
      else
        modelAsScalar

    # Populate the `@patterns` array with all of the "positive" filter
    # expressions (i.e., patterns) in the (OLD-style) filter expression, i.e.,
    # all of the non-negated filter expressions.
    getPatterns: (filter) ->
      if filter.length in [4, 5]
        @patterns.push filter
      else
        if filter[0] in ['and', 'or']
          for junct in filter[1]
            @getPatterns junct

    # Return an object with resource attributes as attributes and regular
    # expressions for matching search pattern matches as values. Setting the
    # `flatten` param to `true` will treat all attribute-values as scalars
    # (i.e., strings or numbers).
    # The `patterns` param is an array of subarrays, where each subarray is a
    # "positive" OLD-style filter expression (positive, meaning that it asserts
    # something content-ful/non-negative of the match). The `patternsObject`
    # returned maps attributes (and `[attribute, subattribute]` duples) to
    # `RegExp` instances.
    getPatternsObject: (patterns, flatten=false) ->
      patternsObject = {}
      for pattern in patterns
        attribute = pattern[1]
        if pattern.length is 4
          relation = pattern[2]
          term = pattern[3]
        else
          subattribute = pattern[2]
          relation = pattern[3]
          term = pattern[4]
        regex = @getRegex relation, term
        if not regex then continue
        if attribute of patternsObject
          if (not flatten) and pattern.length is 5
            if subattribute of patternsObject[attribute]
              patternsObject[attribute][subattribute].push regex
            else
              patternsObject[attribute][subattribute] = [regex]
          else
            patternsObject[attribute].push regex
        else
          if (not flatten) and pattern.length is 5
            patternsObject[attribute] = {}
            patternsObject[attribute][subattribute] = [regex]
          else
            patternsObject[attribute] = [regex]
      for k, v of patternsObject
        if @utils.type(v) is 'object'
          for kk, vv of v
            patternsObject[k][kk] = new RegExp("((?:#{vv.join ')|(?:'}))", 'g')
        else
          patternsObject[k] = new RegExp("((?:#{v.join ')|(?:'}))", 'g')
      patternsObject

    # Take `relation` and `term` and return an appropriate regular expression
    # string. Relations currently accounted for: 'regex', 'like', '=', and
    # 'in'. TODO: relations still needing work: <=, >=, <, and >.
    getRegex: (relation, term) ->
      if relation is 'regex'
        term
      else if relation is 'like'
        # Clip off '%' on the edges so that the later `.replace` call
        # highlights only the pattern and not the entire value.
        if term.length > 1 and term[0] is '%'
          term = term[1...]
        if term.length > 1 and term[term.length - 1] is '%'
          term = term[...-1]
        term.replace(/_/g, '.').replace(/%/g, '.*')
      else if relation is '='
        "^#{term}$"
      else if relation is 'in'
        "(?:^#{term.join ')$|(?:^'})$"
      else
        null

    # Return an object representing the model such that all attribute values
    # are scalars, i.e., strings or numbers.
    getModelAsScalar: ->
      output = {}
      if @orderedAttributes.length
        iterator = @orderedAttributes
      else
        iterator = _.keys @model.attributes
      for attribute in iterator
        value = @model.attributes[attribute]
        output[attribute] = @scalarTransform attribute, value
      output

    # Return `value` as a string (or number).
    # Override this in sub-classes with something better/resource-specific.
    # (Note: this method assumes a File model currently.)
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        value
      else if value
        if attribute in ['elicitor', 'enterer', 'modifier', 'verifier', 'speaker']
          "#{value.first_name} #{value.last_name}"
        else if attribute is 'size'
          @utils.humanFileSize value, true
        else if attribute is 'forms'
          if value.length
            (f.transcription for f in value).join '; '
          else
            ''
        else if attribute is 'tags'
          if value.length
            (t.name for t in value).join ', '
          else
            ''
        else if @utils.type(value) in ['string', 'number']
          value
        else
          JSON.stringify value
      else
        JSON.stringify value

