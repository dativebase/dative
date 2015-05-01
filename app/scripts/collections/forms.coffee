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
        console.log "request to datums_chronological failed; reason: #{reason}"

    ############################################################################
    # CREATE.
    ############################################################################

    # Method to handle the `onload` event of a CORS request to create a
    # form. Delegates to the superclass's method in the OLD case and to a method
    # defined here in the FieldDB case.
    addResourceOnloadHandler: (resource, responseJSON, xhr, payload) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD'
          super resource, responseJSON, xhr, payload
        when 'FieldDB'
          @addResourceOnloadHandlerFieldDB resource, responseJSON, xhr, payload

    # Method to handle the `onload` event of a CORS request to add a
    # FieldDB datum (form).
    addResourceOnloadHandlerFieldDB: (resource, responseJSON, xhr, payload) ->
      resource.trigger "add#{@resourceNameCapitalized}End"
      if xhr.status is 201 and responseJSON.ok is true
        resource.set
          id: responseJSON.id
          _id: responseJSON.id
          _rev: responseJSON.rev
          dateEntered: payload.dateEntered
          dateModified: payload.dateModified
          timestamp: payload.timestamp
          pouchname: payload.pouchname
          comments: payload.comments
        newEnteredByUser = _.findWhere payload.datumFields, label: 'enteredByUser'
        enteredByUser = _.findWhere resource.get('datumFields'), label: 'enteredByUser'
        enteredByUser.value = newEnteredByUser.username
        enteredByUser.mask = newEnteredByUser.username
        enteredByUser.user = newEnteredByUser.user
        resource.trigger 'change'
        resource.trigger "add#{@resourceNameCapitalized}Success"
      else
        errors = responseJSON.errors or {}
        error = responseJSON.error
        resource.trigger "add#{@resourceNameCapitalized}Fail", error, resource
        for attribute, error of errors
          resource.trigger "validationError:#{attribute}", error
        console.log "add (POST) request to
          /#{@getAddResourceURLFieldDB resource} failed (status not 201
          and/or `response.ok != true`)"
        console.log errors

    ############################################################################
    # UPDATE.
    ############################################################################

    # Method to handle the `onload` event of a CORS request to update a
    # form. Delegates to the superclass's method in the OLD case and to a method
    # defined here in the FieldDB case.
    updateResourceOnloadHandler: (resource, responseJSON, xhr, payload) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD'
          super resource, responseJSON, xhr, payload
        when 'FieldDB'
          @updateResourceOnloadHandlerFieldDB resource, responseJSON, xhr, payload

    # Method to handle the `onload` event of a CORS request to update a
    # FieldDB datum (form).
    updateResourceOnloadHandlerFieldDB: (resource, responseJSON, xhr, payload) ->
      resource.trigger "update#{@resourceNameCapitalized}End"
      if xhr.status is 201 and responseJSON.ok is true
        # FieldDB does no server-side processing. We just need to update the
        # CouchDB revision UUID:
        resource.set
          _rev: responseJSON.rev
          dateModified: payload.dateModified
          timestamp: payload.timestamp
          pouchname: payload.pouchname
          comments: payload.comments
        newModifiedByUser = _.findWhere payload.datumFields, label: 'modifiedByUser'
        modifiedByUser = _.findWhere resource.get('datumFields'), label: 'modifiedByUser'
        modifiedByUser.users = newModifiedByUser.users
        resource.trigger 'change'
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
    # PUT <corpus_url>/<pouchname>/<datum_id>?rev=<datum_rev>
    getUpdateResourceURLFieldDB: (resource) ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}/#{resource.get '_id'}?rev=#{resource.get '_rev'}"

    # Return a URL for adding a resource to a web service.
    getAddResourceURL: (resource) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super resource
        when 'FieldDB' then @getAddResourceURLFieldDB resource

    # Returns a URL for adding a resource to a FieldDB web service.
    # POST <corpus_url>/<pouchname>/
    getAddResourceURLFieldDB: (resource) ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}"


    ############################################################################
    # TODOs related to the following two methods.
    ############################################################################

    # TODO: How do I valuate the `version` field of a particular datum field
    # object? Example value I've seen in Spreadsheet: "v2.45.02".
    # Relatedly, How do I set the `version` attribute of a user in
    # `enteredByUser` or `modifiedByUser`?
    # Example value seen: '2.45.02.01.33ss Mon Mar  2 01:37:08 EST 2015'

    # TODO: most FieldDB apps treat the session as a many-to-one required
    # relation; however, I want to treat them as a many-to-many optional
    # relation, i.e., any datum can belong to zero or more sessions. The only
    # problem with this is that some session attributes will need to be
    # present on datums and the denotation of "session" needs to be more
    # general. Here, provisionally, I delete an empty `session` attribute on a
    # create request.

    # TODO: blank comments should never be `setToModel` in the first place.
    # This needs to be handled in the field view.

    # TODO: stop Dative from valuating the timestamps of previously created
    # comments.

    # TODO: the attributes set here for server consumption need to be carefully
    # saved to the client-side model, iff save has succeeded.

    # Returns a representation of a form that a server will accept for form
    # creation.
    getResourceForServerCreate: (resource) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super resource
        when 'FieldDB' then resource.toFieldDBForCreate()

    getResourceForServerUpdate: (resource) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super resource
        when 'FieldDB' then resource.toFieldDBForUpdate()

    # Return an array of `FormModel` instances built from FieldDB objects.
    getDativeFormModelsFromFieldDBObjects: (responseJSON) ->
      (new FormModel()).fieldDB2dative(o) for o in responseJSON.rows

