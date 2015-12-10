define [
  'backbone',
  './../models/resource'
  './../utils/utils'
  './../utils/globals'
], (Backbone, ResourceModel, utils, globals) ->

  # Resources Collection
  # ---------------------
  #
  # Holds models for resources. Houses code for fetching (GET), adding (POST),
  # and updating (PUT) arbitrary resources from an OLD RESTful web service.
  #
  # This is intended to be a base class for other collections, e.g.,
  # PhonologiesCollection. The minimum work required for subclassing is
  # to override `@resourceName` and `@model`.
  #
  # TODO: make this code work for FieldDB web services (if applicable).

  class ResourcesCollection extends Backbone.Collection

    # Override these two attributes in subclasses.
    resourceName: 'resource'
    model: ResourceModel

    # If this is non-null, it is expected to be an object with a `query`
    # attribute and a `paginator` attribute. The presence of such an attribute
    # will change how `fetchResources` behaves.
    search: null

    # If this is non-null, it is expected to be a(n OLD-style) corpus model.
    # The presence of such an attribute will change how `fetchResources`
    # behaves.
    corpus: null

    initialize: (models, options) ->
      @utils = utils
      @resourceNameCapitalized = utils.capitalize @resourceName
      @resourceNamePlural = utils.pluralize @resourceName
      @resourceNamePluralCapitalized = utils.capitalize @resourceNamePlural
      super models, options

    url: 'fake-url'

    ############################################################################
    # FETCH.
    ############################################################################

    # Fetch Resources (with pagination, if needed)
    # OLD case: GET `<URL>/<resource_name_plural>?page=x&items_per_page=y
    # FieldDB case:
    # See http://online-linguistic-database.readthedocs.org/en/latest/interface.html#get-resources
    fetchResources: (options) ->
      Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Start"
      @model.cors.request(
        method: @getResourcesHTTPMethod()
        url: @getResourcesPaginationURL options
        payload: @getResourcesPayload options
        onload: (responseJSON) =>
          @fetchResourcesOnloadHandler responseJSON
        onerror: (responseJSON) =>
          Backbone.trigger "fetch#{@resourceNamePluralCapitalized}End"
          Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Fail",
            "error in fetching #{@getServerSideResourceName()}"
          console.log "Error in GET request to /#{@getServerSideResourceName()}"
      )

    getResourcesHTTPMethod: ->
      if @search or @corpus then 'SEARCH' else 'GET'

    # Return a payload for the `fetchResources` request. Note: there is only a
    # payload if we have a truthy `@search` attribute, which means the fetching
    # is based on a search and uses a SEARCH (non-standard) HTTP method with a
    # payload describing the search (and pagination, and ordering).
    getResourcesPayload: (options) ->
      if @search or @corpus
        if @corpus
          search =
            filter: ["Form", "corpora", "id", "in", [@corpus.get('id')]]
            order_by: ["Form", "id", "desc" ]
        else
          search = @search
        if options.page and options.itemsPerPage
          query: search
          paginator:
            page: options.page
            items_per_page: options.itemsPerPage
        else
          query: search
      else
        null

    # Method to handle the `onload` event of a CORS request to fetch a
    # collection of resources from a server. The default behaviour currently
    # expects an OLD backend. See `collections/forms.coffee` for a FieldDB
    # override/fork.
    fetchResourcesOnloadHandler: (responseJSON) ->
      Backbone.trigger "fetch#{@resourceNamePluralCapitalized}End"
      if 'items' of responseJSON
        @add @getDativeResourceModelsFromOLDObjects(responseJSON.items)
        Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Success",
          responseJSON.paginator
      # The OLD returns `[]` if there are no resources. This is
      # inconsistent and should probably be changed OLD-side.
      else if utils.type(responseJSON) is 'array' and
      responseJSON.length is 0
        Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Success"
      else
        reason = responseJSON.reason or 'unknown'
        Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Fail",
          "failed to fetch all #{@getServerSideResourceName()}; reason:
            #{reason}"
        console.log "GET request to /#{@getServerSideResourceName()} failed; reason:
          #{reason}"


    ############################################################################
    # CREATE.
    ############################################################################

    # Add (create) a resource.
    # POST `<URL>/<resource_name_plural>`
    addResource: (resource, options={}) ->
      resource.trigger "add#{@resourceNameCapitalized}Start"
      payload = @getResourceForServerCreate resource
      monitorProgress = options.monitorProgress or false
      progressModel = options.progressModel or null
      @model.cors.request(
        method: 'POST'
        url: @getAddResourceURL resource
        payload: payload
        monitorProgress: monitorProgress
        progressModel: progressModel
        onload: (responseJSON, xhr) =>
          @addResourceOnloadHandler resource, responseJSON, xhr, payload
        onerror: (responseJSON) =>
          resource.trigger "add#{@resourceNameCapitalized}End"
          resource.trigger "add#{@resourceNameCapitalized}Fail",
            responseJSON.error, resource
          console.log "Error in POST request to /#{@getServerSideResourceName()}"
      )

    # Method to handle the `onload` event of a CORS request to add a
    # particular resource. The default behaviour currently expects an OLD
    # backend. See `collections/forms.coffee` for a FieldDB override/fork.
    addResourceOnloadHandler: (resource, responseJSON, xhr, payload) ->
      resource.trigger "add#{@resourceNameCapitalized}End"
      if xhr.status is 200
        resource.set responseJSON
        resource.trigger "add#{@resourceNameCapitalized}Success", resource
      else
        errors = responseJSON.errors or {}
        if utils.type(errors) is 'object'
          # TODO: each of the following 2 lines is needed in different contexts; find solution!
          resource.trigger "add#{@resourceNameCapitalized}Fail", errors.error
          # resource.trigger "add#{@resourceNameCapitalized}Fail", errors
          for attribute, error of errors
            resource.trigger "validationError:#{attribute}", error
        else
          resource.trigger "add#{@resourceNameCapitalized}Fail", errors
          attribute = @getAttributeForError errors
          if attribute
            resource.trigger "validationError:#{attribute}", errors
          else
            resource.trigger "validationError:general", errors
        console.log "POST request to /#{@getServerSideResourceName()} failed
          (status not 200) ..."
        console.log errors

    # Attempt to match an error string to the resource attribute that caused
    # the error. Return a `null` if not possible. Override this in sub-classes.
    getAttributeForError: (error) -> null


    ############################################################################
    # UPDATE.
    ############################################################################

    # Update a resource.
    # PUT `<URL>/<resource_name_plural>/<resource.id>`
    updateResource: (resource, options) ->
      resource.trigger "update#{@resourceNameCapitalized}Start"
      payload = @getResourceForServerUpdate resource
      @model.cors.request(
        method: 'PUT'
        url: @getUpdateResourceURL resource
        payload: payload
        onload: (responseJSON, xhr) =>
          @updateResourceOnloadHandler resource, responseJSON, xhr, payload
        onerror: (responseJSON) =>
          resource.trigger "update#{@resourceNameCapitalized}End"
          resource.trigger("update#{@resourceNameCapitalized}Fail",
            responseJSON.error, resource)
          console.log "Error in PUT request to /#{@getServerSideResourceName()}"
      )

    # Method to handle the `onload` event of a CORS request to update a
    # particular resource. The default behaviour currently expects an OLD
    # backend. See `collections/forms.coffee` for a FieldDB override/fork.
    updateResourceOnloadHandler: (resource, responseJSON, xhr, payload) ->
      resource.trigger "update#{@resourceNameCapitalized}End"
      if xhr.status is 200
        # We remove the `search` value from the response before we set it; we
        # don't want to assign a new object to this attribute because various
        # views are tied to these (mutable) objects.
        if 'search' of responseJSON then delete responseJSON.search
        resource.set responseJSON
        resource.trigger "update#{@resourceNameCapitalized}Success"
      else
        errors = responseJSON.errors or {}
        error = responseJSON.error
        resource.trigger "update#{@resourceNameCapitalized}Fail", error, resource
        for attribute, error of errors
          resource.trigger "validationError:#{attribute}", error
        console.log "PUT request to /#{@getServerSideResourceName()} failed (status
          not 200) ..."
        console.log errors


    ############################################################################
    # Helpers
    ############################################################################

    getOLDURL: ->
      globals.applicationSettings.get('activeServer').get 'url'

    # The default is to just use the plural form of the resource name as the
    # server-side name for the resource; however, this can be overridden with
    # `@serverSideResourceName`, as is necessary with "subcorpora"/"corpora".
    getServerSideResourceName: ->
      @serverSideResourceName or @resourceNamePlural.toLowerCase()

    # Return a URL for requesting a page of <resource_name_plural> from an OLD
    # web service. GET parameters control pagination and ordering. See
    # `collections/forms.coffee` for a FieldDB-specific override.
    # Note: other possible parameters: `order_by_model`, `order_by_attribute`,
    # and `order_by_direction`.
    getResourcesPaginationURL: (options={}) ->
      if @search or @corpus
        "#{@getOLDURL()}/#{@getServerSideResourceName()}"
      else if options.page and options.itemsPerPage
        "#{@getOLDURL()}/#{@getServerSideResourceName()}?\
          page=#{options.page}&\
          items_per_page=#{options.itemsPerPage}"
      else
        "#{@getOLDURL()}/#{@getServerSideResourceName()}"

    # Return a URL for updating a resource on an OLD web service. See
    # `collections/forms.coffee for a FieldDB-specific override.
    getUpdateResourceURL: (resource) ->
      "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{resource.get 'id'}"

    # Return a URL for adding a resource to an OLD web service. See
    # `collections/forms.coffee for a FieldDB-specific override.
    getAddResourceURL: (resource) ->
      "#{@getOLDURL()}/#{@getServerSideResourceName()}"

    # Return a representation of `resource` that the server will accept (for a
    # create or update request). See `collections/forms.coffee for a
    # FieldDB-specific override.
    getResourceForServer: (resource) ->
      resource.toOLD()

    # Return a representation of `resource` that the server will accept for a
    # create request.
    getResourceForServerCreate: (resource) ->
      @getResourceForServer resource

    # Return a representation of `resource` that the server will accept for an
    # update request.
    getResourceForServerUpdate: (resource) ->
      @getResourceForServer resource

    # Return an array of `@model` instances built from OLD objects.
    getDativeResourceModelsFromOLDObjects: (responseJSON) ->
      (new @model(o) for o in responseJSON)

