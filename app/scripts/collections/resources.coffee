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

    initialize: (models, options) ->
      @resourceNameCapitalized = utils.capitalize @resourceName
      @resourceNamePlural = utils.pluralize @resourceName
      @resourceNamePluralCapitalized = utils.capitalize @resourceNamePlural
      super models, options

    url: 'fake-url'

    # Fetch Resources (with pagination, if needed)
    # GET `<URL>/<resource_name_plural>?page=x&items_per_page=y
    # See http://online-linguistic-database.readthedocs.org/en/latest/interface.html#get-resources
    fetchResources: (options) ->
      Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Start"
      @model.cors.request(
        method: 'GET'
        url: @getResourcesPaginationURL options
        onload: (responseJSON) =>
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
              "failed to fetch all #{@resourceNamePlural}; reason:
                #{reason}"
            console.log "GET request to /#{@resourceNamePlural} failed; reason:
              #{reason}"
        onerror: (responseJSON) =>
          Backbone.trigger "fetch#{@resourceNamePluralCapitalized}End"
          Backbone.trigger "fetch#{@resourceNamePluralCapitalized}Fail",
            "error in fetching #{@resourceNamePlural}"
          console.log "Error in GET request to /#{@resourceNamePlural}"
      )

    # Add (create) a resource.
    # POST `<URL>/<resource_name_plural>`
    addResource: (resource, options) ->
      resource.trigger "add#{@resourceNameCapitalized}Start"
      @model.cors.request(
        method: 'POST'
        url: "#{@getOLDURL()}/#{@resourceNamePlural}"
        payload: resource.toOLD()
        onload: (responseJSON, xhr) =>
          resource.trigger "add#{@resourceNameCapitalized}End"
          if xhr.status is 200
            resource.set responseJSON
            resource.trigger "add#{@resourceNameCapitalized}Success", resource
          else
            errors = responseJSON.errors or {}
            error = errors.error
            resource.trigger "add#{@resourceNameCapitalized}Fail", error
            for attribute, error of errors
              resource.trigger "validationError:#{attribute}", error
            console.log "POST request to /#{@resourceNamePlural} failed (status
              not 200) ..."
            console.log errors
        onerror: (responseJSON) =>
          resource.trigger "add#{@resourceNameCapitalized}End"
          resource.trigger "add#{@resourceNameCapitalized}Fail",
            responseJSON.error, resource
          console.log "Error in POST request to /#{@resourceNamePlural}"
      )

    # Update a resource.
    # PUT `<URL>/<resource_name_plural>/<resource.id>`
    updateResource: (resource, options) ->
      resource.trigger "update#{@resourceNameCapitalized}Start"
      @model.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/#{@resourceNamePlural}/#{resource.get 'id'}"
        payload: resource.toOLD()
        onload: (responseJSON, xhr) =>
          resource.trigger "update#{@resourceNameCapitalized}End"
          if xhr.status is 200
            resource.set responseJSON
            resource.trigger "update#{@resourceNameCapitalized}Success"
          else
            errors = responseJSON.errors or {}
            error = responseJSON.error
            resource.trigger "update#{@resourceNameCapitalized}Fail", error, resource
            for attribute, error of errors
              resource.trigger "validationError:#{attribute}", error
            console.log "PUT request to /#{@resourceNamePlural} failed (status
              not 200) ..."
            console.log errors
        onerror: (responseJSON) =>
          resource.trigger "update#{@resourceNameCapitalized}End"
          resource.trigger "update#{@resourceNameCapitalized}Fail", responseJSON.error,
            resource
          console.log "Error in PUT request to /#{@resourceNamePlural}"
      )

    ############################################################################
    # Helpers
    ############################################################################

    getOLDURL: ->
      globals.applicationSettings.get('activeServer').get 'url'

    # Return a URL for requesting a page of <resource_name_plural> from an OLD web service.
    # GET parameters control pagination and ordering.
    # Note: other possible parameters: `order_by_model`, `order_by_attribute`,
    # and `order_by_direction`.
    getResourcesPaginationURL: (options) ->
      if options.page and options.itemsPerPage
        "#{@getOLDURL()}/#{@resourceNamePlural}?\
          page=#{options.page}&\
          items_per_page=#{options.itemsPerPage}"
      else
        "#{@getOLDURL()}/#{@resourceNamePlural}"

    # Return an array of `@model` instances built from OLD objects.
    getDativeResourceModelsFromOLDObjects: (responseJSON) ->
      (new @model(o) for o in responseJSON)

