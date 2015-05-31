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

    serverSideResourceName: 'formsearches'


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
        filter: ['Form', 'transcription', 'like', '%']
        order_by: ['Form', 'id', 'desc']

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null              # An integer relational id
      enterer: null         # an object (attributes: `id`, `first_name`,
                            # `last_name`, `role`)
      datetime_modified: "" # <string>  (datetime search was last modified;
                            # format and construction same as
                            # `datetime_entered`.)

    # We listen to this once so that we can add the result of calling GET
    # /forms/new_search to the result of calling GET /formsearches/new.
    getNewFormSearchDataSuccess: (newSearchData) ->
      @searchNewData.search_search_parameters = newSearchData
      Backbone.trigger "getNew#{@resourceNameCapitalized}DataSuccess", @searchNewData

    # We listen to this once so that we can tell the user that the request to
    # GET /forms/new_search failed.
    getNewFormSearchDataFail: ->
      Backbone.trigger "getNew#{@resourceNameCapitalized}DataFail",
          "Error in GET request to OLD server for /forms/new_search"

    # Get the data necessary to create a new search over form objects.
    # Note: this is an override of the base `ResourceModel`'s implementation of
    # this method since here we need to also request GET /forms/new_search.
    # We do this by first requesting GET /formsearches/new and then, if that's
    # successful, requesting GET /forms/new_search. If that's successful, we
    # trigger the standard Backbone-wide success event for this method, passing
    # in an integrated object.
    getNewResourceData: ->
      Backbone.trigger "getNew#{@resourceNameCapitalized}DataStart"
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/new"
        onload: (responseJSON, xhr) =>
          Backbone.trigger "getNew#{@resourceNameCapitalized}DataEnd"
          if xhr.status is 200
            @searchNewData = responseJSON
            @listenToOnce Backbone, 'getNewFormSearchDataSuccess', @getNewFormSearchDataSuccess
            @listenToOnce Backbone, 'getNewFormSearchDataFail', @getNewFormSearchDataFail
            (new FormModel()).getNewSearchData()
          else
            Backbone.trigger "getNew#{@resourceNameCapitalized}DataFail",
              "Failed in fetching the data required to create new
                #{@getServerSideResourceName()}."
        onerror: (responseJSON) =>
          Backbone.trigger "getNew#{@resourceNameCapitalized}DataEnd"
          Backbone.trigger "getNew#{@resourceNameCapitalized}DataFail",
            "Error in GET request to OLD server for /#{@getServerSideResourceName()}/new"
          console.log "Error in GET request to OLD server for
            /#{@getServerSideResourceName()}/new"
      )

