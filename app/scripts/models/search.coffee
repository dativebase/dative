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
      datetime_modified: "" # <string>  (datetime search was last modified;
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

