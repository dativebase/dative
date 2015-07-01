define [
    './base'
    './../utils/globals'
  ], (BaseModel, globals) ->

  # Resource Model
  # ---------------
  #
  # A Backbone model for Dative resources, e.g., OLD corpora.
  #
  # This model is intended for sub-classing. At a minimum, the `@resourceName`
  # attribute should be overridden.

  class ResourceModel extends BaseModel

    # Override this in subclasses.
    resourceName: 'resource'

    # Override this in the sub-class with something sensible, i.e., something
    # that makes sense for the resource model being represented here.
    defaults: ->

    # Override this in subclasses to indicate which attributes can be edited by
    # users.
    editableAttributes: []

    initialize: (attributes, options) ->
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural
      options = options or {}
      if options.collection then @collection = options.collection
      @activeServerType = @getActiveServerType()
      super attributes, options

    # Backbone throws 'A "url" property or function must be specified' if this
    # is not present.
    url: 'fakeurl'

    getActiveServerType: ->
      try
        globals.applicationSettings.get('activeServer').get 'type'
      catch
        'OLD'

    # Validate the model. If there are errors, returns an object with errored
    # attributes as keys and error messages as values; otherwise returns
    # `undefined`.
    validate: (attributes, options) ->
      attributes = attributes or @attributes
      errors = {}
      for attribute, value of attributes
        attributeValidator = @getValidator attribute
        if attributeValidator
          error = attributeValidator.apply @, [value]
          if error then errors[attribute] = error
      if _.isEmpty errors then undefined else errors

    # Override this in subclasses for validation: return a `@validator` method
    # for the input `attribute`, or `null` if it shouldn't be validated.
    getValidator: (attribute) -> null

    # The OLD web service expects ids or arrays of ids as input for relational
    # attributes. However, Dative stores the values of such attributes as
    # objects (with id attributes) or arrays of such objects. Specifying the
    # relational attributes in these arrays allows `toOLD` to work correctly.
    manyToOneAttributes: []
    manyToManyAttributes: []

    # Return a representation of the model's state that the OLD likes: i.e.,
    # with relational values as ids or arrays thereof. Note that there is no
    # general `toFieldDB` method, since I am unsure a) whether other FieldDB
    # objects expose a similar RESTful resource-based interface (sessions?,
    # comments?, corpora?, message_feeds?)
    toOLD: ->
      result = _.clone @attributes
      # Not doing this causes a `RangeError: Maximum call stack size exceeded`
      # when cors.coffee tries to call `JSON.stringify` on a resource model that
      # contains a resources collection that contains that same resource model,
      # etc. ad infinitum.
      delete result.collection
      for attribute in @manyToOneAttributes
        result[attribute] = result[attribute]?.id or null
      for attribute in @manyToManyAttributes
        result[attribute] = (v.id for v in result[attribute] or [])
      result

    ############################################################################
    # Resource Schema
    ############################################################################

    # Returns `true` if the model is empty.
    isEmpty: ->
      attributes = _.clone @attributes
      delete attributes.collection
      _.isEqual @defaults(), attributes

    getOLDURL: -> globals.applicationSettings.get('activeServer').get 'url'

    # The default is to just use the plural form of the resource name as the
    # server-side name for the resource; however, this can be overridden with
    # `@serverSideResourceName`, as is necessary with OLD "corpora" which are
    # called "subcorpora" in Dative.
    getServerSideResourceName: ->
      @serverSideResourceName or @resourceNamePlural.toLowerCase()

    # Fetch a resource by id.
    # GET `<URL>/<resource_name_plural>/<resource.id>`
    fetchResource: (id) ->
      @trigger "fetch#{@resourceNameCapitalized}Start"
      @constructor.cors.request(
        method: 'GET'
        url: @getFetchResourceURL id
        onload: (responseJSON, xhr) =>
          @fetchResourceOnloadHandler responseJSON, xhr
        onerror: (responseJSON) =>
          @trigger "fetch#{@resourceNameCapitalized}End"
          error = responseJSON.error or 'No error message provided.'
          @trigger "fetch#{@resourceNameCapitalized}Fail", error, @
          console.log "Error in GET request to
            /#{@getServerSideResourceName()}/#{@get 'id'} (onerror triggered)."
      )

    # The type of URL used to fetch a resource on an OLD backend.
    getFetchResourceURL: (id) ->
      "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{id}"

    fetchResourceOnloadHandler: (responseJSON, xhr) ->
      @trigger "fetch#{@resourceNameCapitalized}End"
      if xhr.status is 200
        @trigger "fetch#{@resourceNameCapitalized}Success", responseJSON
      else
        error = responseJSON.error or 'No error message provided.'
        @trigger "fetch#{@resourceNameCapitalized}Fail", error, @
        console.log "GET request to /#{@getServerSideResourceName()}/#{@get 'id'}
          failed (status not 200)."
        console.log error

    # Issue a GET request to /<resource_name_plural>/new on the active OLD
    # server. In the OLD API, this type of request returns a JSON object
    # containing the data necessary to create a new OLD resource.
    getNewResourceData: ->
      @trigger "getNew#{@resourceNameCapitalized}DataStart"
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/new"
        onload: (responseJSON, xhr) =>
          @trigger "getNew#{@resourceNameCapitalized}DataEnd"
          if xhr.status is 200
            @trigger "getNew#{@resourceNameCapitalized}DataSuccess",
              responseJSON
          else
            @trigger "getNew#{@resourceNameCapitalized}DataSuccess",
              "Failed in fetching the data required to create new
                #{@getServerSideResourceName()}."
        onerror: (responseJSON) =>
          @trigger "getNew#{@resourceNameCapitalized}DataEnd"
          @trigger "getNew#{@resourceNameCapitalized}DataFail",
            "Error in GET request to OLD server for /#{@getServerSideResourceName()}/new"
          console.log "Error in GET request to OLD server for
            /#{@getServerSideResourceName()}/new"
      )

    # Issue a GET request to /<resource_name_plural>/new_search on the active OLD
    # server. In the OLD API, this type of request returns a JSON object
    # containing the data necessary to create a new OLD search over that resource.
    getNewSearchData: ->
      @trigger "getNew#{@resourceNameCapitalized}SearchDataStart"
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/new_search"
        onload: (responseJSON, xhr) =>
          @trigger "getNew#{@resourceNameCapitalized}SearchDataEnd"
          if xhr.status is 200
            @trigger "getNew#{@resourceNameCapitalized}SearchDataSuccess",
              responseJSON
          else
            @trigger "getNew#{@resourceNameCapitalized}SearchDataSuccess",
              "Failed in fetching the data required to create a new search over
                #{@resourceNamePlural}."
        onerror: (responseJSON) =>
          @trigger "getNew#{@resourceNameCapitalized}SearchDataEnd"
          @trigger "getNew#{@resourceNameCapitalized}SearchDataFail",
            "Error in GET request to OLD server for /#{@getServerSideResourceName()}/new_search"
          console.log "Error in GET request to OLD server for
            /#{@getServerSideResourceName()}/new_search"
      )

    # Destroy a resource.
    # DELETE `<URL>/<resource_name_plural>/<resource.id>`
    destroyResource: (options) ->
      Backbone.trigger "destroy#{@resourceNameCapitalized}Start"
      @constructor.cors.request(
        method: @getDestroyResourceHTTPMethod()
        url: @getDestroyResourceURL()
        payload: @getDestroyResourcePayload()
        onload: (responseJSON, xhr) =>
          @destroyResourceOnloadHandler responseJSON, xhr
        onerror: (responseJSON) =>
          Backbone.trigger "destroy#{@resourceNameCapitalized}End"
          error = responseJSON.error or 'No error message provided.'
          Backbone.trigger "destroy#{@resourceNameCapitalized}Fail", error
          console.log "Error in DELETE request to
            /#{@getServerSideResourceName()}/#{@get 'id'} (onerror triggered)."
      )

    destroyResourceOnloadHandler: (responseJSON, xhr) ->
      Backbone.trigger "destroy#{@resourceNameCapitalized}End"
      if xhr.status is 200
        Backbone.trigger "destroy#{@resourceNameCapitalized}Success", @
      else
        error = responseJSON.error or 'No error message provided.'
        Backbone.trigger "destroy#{@resourceNameCapitalized}Fail", error
        console.log "DELETE request to /#{@getServerSideResourceName()}/#{@get 'id'}
          failed (status not 200)."
        console.log error

    # This is its own function because in the FieldDB case it's a PUT request.
    getDestroyResourceHTTPMethod: ->
      'DELETE'

    # The type of URL used to destroy a resource on an OLD backend.
    getDestroyResourceURL: ->
      "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}"

    # The JSON payload for destroying a resource; the OLD doesn't use this, but
    # FieldDB crucially does.
    getDestroyResourcePayload: -> null

    # Perform a "generate and compile" request.
    # PUT `<URL>/morphologicalparsers/{id}/generate_and_compile`
    # NOTE: this is only relevant to FST-based resources that need to be
    # generated and compiled, i.e., just morphologies and morphological
    # parsers, I think.
    # NOTE 2: I purposefully pass `@` here so that events relayed through
    # `Backbone` can know which morphology failed/succeeded.
    generateAndCompile: ->
      @trigger "generateAndCompileStart"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/generate_and_compile"
        onload: (responseJSON, xhr) =>
          @trigger "generateAndCompileEnd"
          if xhr.status is 200
            @trigger "generateAndCompileSuccess", responseJSON, @
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "generateAndCompileFail", error, @
            console.log "PUT request to
              #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/generate_and_compile
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "generateAndCompileEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "generateAndCompileFail", error, @
          console.log "Error in PUT request to
            #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/generate_and_compile
            (onerror triggered)."
      )

    # Perform a search request.
    # SEARCH `<URL>/<resource_name_plural>/` or
    # POST `<URL>/<resource_name_plural>/search`
    # Payload guide:
    #  {
    #    "query": {
    #      "filter": [ ... ],
    #      "order_by": [ ... ]
    #    },
    #    "paginator": { ... }
    #  }
    getSearchPayload: (query, paginator) ->
      paginator = paginator or {page: 1, items_per_page: 10}
      if 'order_by' not of query then query.order_by = ['Form', 'id', 'asc']
      query: query
      paginator: paginator

    search: (query, paginator=null) ->
      @trigger "searchStart"
      @constructor.cors.request(
        method: 'SEARCH'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}"
        payload: @getSearchPayload query, paginator
        onload: (responseJSON, xhr) =>
          @trigger "searchEnd"
          if xhr.status is 200
            @trigger "searchSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "searchFail", error
            console.log "SEARCH request to
              #{@getOLDURL()}/#{@getServerSideResourceName()}
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "searchEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "searchFail", error
          console.log "Error in SEARCH request to
            #{@getOLDURL()}/#{@getServerSideResourceName()}
            (onerror triggered)."
      )

