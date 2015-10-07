define [
  './resource'
  './form'
], (ResourceModel, FormModel) ->

  # Search Model
  # ---------------
  #
  # A Backbone model for Dative searches.

  class SearchModel extends ResourceModel

    resourceName: 'search'

    # Change some or all of the following four attributes if this search model
    # is being used to search over a resource other than forms, e.g., over file
    # resources.
    targetResourceName: 'form'
    targetResourcePrimaryAttribute: 'transcription'
    targetModelClass: FormModel

    # This may need to be overridden when this SearchModel is used to search
    # over models that don't have "id" as their primary key, e.g., OLD
    # languages which have the ISO 639-3 "Id" as their primary key.
    targetResourcePrimaryKey: 'id'

    getTargetResourceNameCapitalized: ->
      @utils.capitalize @targetResourceName

    serverSideResourceName: 'formsearches'

    initialize: (attributes, options) ->
      super attributes, options
      @targetResourceNameCapitalized = @getTargetResourceNameCapitalized()
      @targetResourceNamePlural = @utils.pluralize @targetResourceName
      @targetResourceNamePluralCapitalized =
        @utils.capitalize @targetResourceNamePlural

    editableAttributes: [
      'name'
      'description'
      'search'
    ]

    manyToOneAttributes: []

    manyToManyAttributes: []

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

    ############################################################################
    # Search Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L846-L854
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/formsearch.py
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py

    defaults: ->
      name: ''              # required, unique among search names, max 255 chars
      description: ''       # string description
      search:
        filter: [
          @getTargetResourceNameCapitalized()
          @targetResourcePrimaryAttribute
          'like'
          '%'
        ]
        order_by: [
          @getTargetResourceNameCapitalized()
          @targetResourcePrimaryKey
          'asc'
        ]

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null              # An integer relational id
      enterer: null         # an object (attributes: `id`, `first_name`,
                            # `last_name`, `role`)
      datetime_modified: "" # <string>  (datetime search was last modified,
                            # format and construction same as
                            # `datetime_entered`.)

    # We listen to this once so that we can add the result of calling GET
    # /<target_resource_plural>/new_search to the result of calling GET
    # /formsearches/new.
    getNewTargetResourceSearchDataSuccess: (newSearchData) ->
      key = "#{@targetResourceName}_search_parameters"
      @searchNewData[key] = newSearchData.search_parameters
      @trigger "getNew#{@resourceNameCapitalized}DataSuccess", @searchNewData

    # We listen to this once so that we can tell the user that the request to
    # GET /<target_resource_plural>/new_search failed.
    getNewTargetResourceSearchDataFail: ->
      @trigger "getNew#{@resourceNameCapitalized}DataFail",
          "Error in GET request to OLD server for
            /#{@targetResourceNamePlural}/new_search"

    # Get the data necessary to create a new search over <target_resource>
    # objects. Note: this is an override of the base `ResourceModel`'s
    # implementation of this method since here we need to also request GET
    # /<target_resource_plural>/new_search. We do this by first requesting GET
    # /formsearches/new and then, if that's successful, requesting GET
    # /<target_resource_plural>/new_search. If that's successful, we trigger
    # the standard Backbone-wide success event for this method, passing in an
    # integrated/extended object.
    getNewResourceData: ->
      @trigger "getNew#{@resourceNameCapitalized}DataStart"
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/new"
        onload: (responseJSON, xhr) =>
          @trigger "getNew#{@resourceNameCapitalized}DataEnd"
          if xhr.status is 200
            @searchNewData = responseJSON
            ourTargetModel = new @targetModelClass()
            @listenToOnce(ourTargetModel,
              "getNew#{@targetResourceNameCapitalized}SearchDataSuccess",
              @getNewTargetResourceSearchDataSuccess)
            @listenToOnce(ourTargetModel,
              "getNew#{@targetResourceNameCapitalized}SearchDataFail",
              @getNewTargetResourceSearchDataFail)
            ourTargetModel.getNewSearchData()
          else
            @trigger "getNew#{@resourceNameCapitalized}DataFail",
              "Failed in fetching the data required to create new
                #{@getServerSideResourceName()}."
        onerror: (responseJSON) =>
          @trigger "getNew#{@resourceNameCapitalized}DataEnd"
          @trigger "getNew#{@resourceNameCapitalized}DataFail",
            "Error in GET request to OLD server for /#{@getServerSideResourceName()}/new"
          console.log "Error in GET request to OLD server for
            /#{@getServerSideResourceName()}/new"
      )

    ############################################################################
    # Logic for returning a "patterns object" for the search model.
    ############################################################################

    # A patterns object is an object that maps attributes to regular
    # expressions that can be used to highlight the attribute's value in order
    # to better indicate why a given resource matches the search model.

    getPatternsObject: ->
      patterns = @getPatterns @get('search').filter
      @_getPatternsObject patterns

    # Return a "patterns" array with all of the "positive" filter
    # expressions (i.e., patterns) in the (OLD-style) filter expression, i.e.,
    # all of the non-negated filter expressions.
    getPatterns: (filter) ->
      patterns = []
      if filter.length in [4, 5]
        patterns.push filter
      else
        if filter[0] in ['and', 'or']
          for junct in filter[1]
            patterns = patterns.concat @getPatterns(junct)
      patterns

    # Return an object with resource attributes as attributes and regular
    # expressions for matching search pattern matches as values. Setting the
    # `flatten` param to `true` will treat all attribute-values as scalars
    # (i.e., strings or numbers).
    # The `patterns` param is an array of subarrays, where each subarray is a
    # "positive" OLD-style filter expression (positive, meaning that it asserts
    # something content-ful/non-negative of the match). The `patternsObject`
    # returned maps attributes (and `[attribute, subattribute]` duples) to
    # `RegExp` instances.
    _getPatternsObject: (patterns, flatten=false) ->
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
        regex = term
      else if relation is 'like'
        # Clip off '%' on the edges so that the later `.replace` call
        # highlights only the pattern and not the entire value.
        if term.length > 1 and term[0] is '%'
          term = term[1...]
        if term.length > 1 and term[term.length - 1] is '%'
          term = term[...-1]
        regex = @escapeRegexChars(term).replace(/_/g, '.').replace(/%/g, '.*')
      else if relation is '='
        regex = "^#{@escapeRegexChars term}$"
      else if relation is 'in'
        regex = "(?:^#{term.join ')$|(?:^'})$"
      else
        regex = null

      # The OLD NFD-Unicode normalizes all data. So we need to normalize our
      # regex string in order for all matches to work out correctly.
      try
        regex.normalize 'NFD'
      catch
        regex

    # Cf. http://stackoverflow.com/a/9310752/992730
    escapeRegexChars: (input) -> input.replace /[-[\]{}()*+?.,\\^$|#]/g, "\\$&"

