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
      # TODO: this `collection` should be in options, not attributes ...
      if attributes?.collection then @collection = attributes.collection
      @activeServerType = @getActiveServerType()
      super attributes, options

    # Backbone throws 'A "url" property or function must be specified' if this
    # is not present.
    url: 'fakeurl'

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'

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
      # TODO: this should be fixed once we take `collection` out of the
      # `attributes` input array in the constructor!
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
      # TODO: this should be fixed once we take `collection` out of the
      # `attributes` input array in the constructor!
      delete attributes.collection
      _.isEqual @defaults(), attributes

    getOLDURL: -> globals.applicationSettings.get('activeServer').get 'url'

    # The default is to just use the plural form of the resource name as the
    # server-side name for the resource; however, this can be overridden with
    # `@serverSideResourceName`, as is necessary with OLD "corpora" which are
    # called "subcorpora" in Dative.
    getServerSideResourceName: ->
      @serverSideResourceName or @resourceNamePlural

    # Issue a GET request to /<resource_name_plural>/new on the active OLD
    # server. In the OLD API, this type of request returns a JSON object
    # containing the data necessary to create a new OLD resource.
    getNewResourceData: ->
      Backbone.trigger "getNew#{@resourceNameCapitalized}DataStart"
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/new"
        onload: (responseJSON, xhr) =>
          Backbone.trigger "getNew#{@resourceNameCapitalized}DataEnd"
          if xhr.status is 200
            Backbone.trigger "getNew#{@resourceNameCapitalized}DataSuccess",
              responseJSON
          else
            Backbone.trigger "getNew#{@resourceNameCapitalized}DataSuccess",
              "Failed in fetching the data required to create new
                #{@getServerSideResourceName()}."
        onerror: (responseJSON) =>
          Backbone.trigger "getNew#{@resourceNameCapitalized}DataEnd"
          Backbone.trigger "getNew#{@resourceNameCapitalized}DataFail",
            "Error in GET request to OLD server for /#{@getServerSideResourceName()}/new"
          console.log "Error in GET request to OLD server for
            /#{@getServerSideResourceName()}/new")

    # Destroy a resource.
    # DELETE `<URL>/<resource_name_plural>/<resource.id>`
    destroyResource: (options) ->
      Backbone.trigger "destroy#{@resourceNameCapitalized}Start"
      @constructor.cors.request(
        method: 'DELETE'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}"
        onload: (responseJSON, xhr) =>
          Backbone.trigger "destroy#{@resourceNameCapitalized}End"
          if xhr.status is 200
            Backbone.trigger "destroy#{@resourceNameCapitalized}Success", @
          else
            error = responseJSON.error or 'No error message provided.'
            Backbone.trigger "destroy#{@resourceNameCapitalized}Fail", error
            console.log "DELETE request to /#{@getServerSideResourceName()}/#{@get 'id'}
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          Backbone.trigger "destroy#{@resourceNameCapitalized}End"
          error = responseJSON.error or 'No error message provided.'
          Backbone.trigger "destroy#{@resourceNameCapitalized}Fail", error
          console.log "Error in DELETE request to
            /#{@getServerSideResourceName()}/#{@get 'id'} (onerror triggered)."
      )

