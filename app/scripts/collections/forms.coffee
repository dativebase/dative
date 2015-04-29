define [
  './resources'
  './../models/form'
  './../utils/globals'
  './../utils/utils'
], (ResourcesCollection, FormModel, globals, utils) ->

  # Forms Collection
  # ----------------
  #
  # Holds models for forms.

  class FormsCollection extends ResourcesCollection

    resourceName: 'form'
    model: FormModel


    ############################################################################
    # FETCH.
    ############################################################################

    # Method to handle the `onload` event of a CORS request to fetch a
    # collection of forms from a server. In the OLD case, we use the
    # superclass method; in the FieldDB case, we use a custom handler defined
    # below.
    fetchResourcesOnloadHandler: (responseJSON) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super responseJSON
        when 'FieldDB' then @fetchResourcesOnloadHandlerFieldDB responseJSON

    # Method to handle the `onload` event of a CORS request to fetch a
    # page of datums from a FieldDB server.
    fetchResourcesOnloadHandlerFieldDB: (responseJSON) ->
      Backbone.trigger "fetch#{@resourceNamePluralCapitalized}End"
      if responseJSON.rows
        @add @getDativeFormModelsFromFieldDBObjects(responseJSON)
        # The view that listens to `fetchFieldDBFormsSuccess` needs as
        # argument a "paginator", which in this case just means an object
        # with a `count` attribute.
        paginator = count: responseJSON.total_rows
        Backbone.trigger("fetch#{@resourceNamePluralCapitalized}Success",
          paginator)
      else
        reason = responseJSON.reason or 'unknown'
        Backbone.trigger("fetch#{@resourceNamePluralCapitalized}Fail",
          "Failed in fetching the data. #{reason}")
        console.log ["request to datums_chronological failed;",
          "reason: #{reason}"].join ' '


    ############################################################################
    # UPDATE.
    ############################################################################

    # Method to handle the `onload` event of a CORS request to update a
    # form. Delegates to the superclass's method in the OLD case and to a method
    # defined here in the FieldDB case.
    updateResourcesOnloadHandler: (resource, responseJSON, xhr) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD'
          super resource, responseJSON, xhr
        when 'FieldDB'
          @updateResourcesOnloadHandlerFieldDB resource, responseJSON, xhr

    # Method to handle the `onload` event of a CORS request to update a
    # FieldDB datum (form).
    updateResourcesOnloadHandlerFieldDB: (resource, responseJSON, xhr) ->
      resource.trigger "update#{@resourceNameCapitalized}End"
      if xhr.status is 201 and responseJSON.ok is true
        # FieldDB does no server-side processing. We just need to update the
        # CouchDB revision UUID:
        resource.set '_rev', responseJSON.rev
        resource.trigger "update#{@resourceNameCapitalized}Success"
      else
        errors = responseJSON.errors or {}
        error = responseJSON.error
        resource.trigger "update#{@resourceNameCapitalized}Fail", error, resource
        for attribute, error of errors
          resource.trigger "validationError:#{attribute}", error
        console.log "Update (PUT) request to
          /#{@getUpdateResourceURLFieldDB resource} failed (status not 201
          and/or `response.ok != true`)"
        console.log errors


    ############################################################################
    # Helpers.
    ############################################################################

    # Returns the URL for fetching a page of resources.
    getResourcesPaginationURL: (options) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super options
        when 'FieldDB' then @getFieldDBFormsPaginationURL options

    # Returns the FieldDB URL for fetching a page of datums.
    getFieldDBFormsPaginationURL: (options) ->
      url = @getFetchAllFieldDBFormsURL()
      if options.page and options.page isnt 0 and options.itemsPerPage
        skip = (options.page - 1) * options.itemsPerPage
        "#{url}?limit=#{options.itemsPerPage}&skip=#{skip}"
      else
        "#{url}?limit=#{options.itemsPerPage}"

    # Returns the FieldDB URL for fetching all datums in a corpus, in
    # chronological order.
    getFetchAllFieldDBFormsURL: ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}/_design/pages/_view/datums_chronological"

    # Returns a URL for updating a resource on a web service.
    getUpdateResourceURL: (resource) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super resource
        when 'FieldDB' then @getUpdateResourceURLFieldDB resource

    # Returns a URL for updating a resource on a FieldDB web service.
    # GET <corpus_url>/<pouchname>/<datum_id>?rev=<datum_rev>
    getUpdateResourceURLFieldDB: (resource) ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}/#{resource.get '_id'}?rev=#{resource.get '_rev'}"

    # Returns a representation of a form that a server will accept.
    getResourceForServer: (resource) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super resource
        when 'FieldDB' then resource.toFieldDB()

    # Return an array of `FormModel` instances built from FieldDB objects.
    getDativeFormModelsFromFieldDBObjects: (responseJSON) ->
      (new FormModel()).fieldDB2dative(o) for o in responseJSON.rows

