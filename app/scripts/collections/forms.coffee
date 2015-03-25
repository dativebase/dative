define [
  'backbone',
  './../models/form'
  './../utils/utils'
  './../utils/globals'
], (Backbone, FormModel, utils, globals) ->

  # Forms Collection
  # ----------------
  #
  # Holds models for forms.

  class FormsCollection extends Backbone.Collection

    model: FormModel
    url: 'fake-url'

    # Fetch *all* FieldDB forms.
    # GET `<CorpusServiceURL>/<pouchname>/_design/pages/_view/datums_chronological`
    fetchAllFieldDBForms: ->
      Backbone.trigger 'fetchAllFieldDBFormsStart'
      FormModel.cors.request(
        method: 'GET'
        url: @getFetchAllFieldDBFormsURL()
        onload: (responseJSON) =>
          Backbone.trigger 'fetchAllFieldDBFormsEnd'
          if responseJSON.rows
            @add @getDativeFormModelsFromFieldDBObjects(responseJSON)
            Backbone.trigger 'fetchAllFieldDBFormsSuccess'
          else
            reason = responseJSON.reason or 'unknown'
            Backbone.trigger 'fetchAllFieldDBFormsFail',
              "Failed in fetching the data. #{reason}"
            console.log ["request to datums_chronological failed;",
              "reason: #{reason}"].join ' '
        onerror: (responseJSON) =>
          console.log 'Error in request to datums_chronological'
          Backbone.trigger 'fetchAllFieldDBFormsEnd'
          Backbone.trigger 'fetchAllFieldDBFormsFail', 'error in fetching all
            fielddb forms'
          console.log 'Error in request to datums_chronological'
      )

    # Fetch OLD Forms
    # GET `<OLD_URL>/forms?page=x&items_per_page=y
    # See http://online-linguistic-database.readthedocs.org/en/latest/interface.html#get-resources
    fetchOLDForms: (options) ->
      Backbone.trigger 'fetchOLDFormsStart'
      FormModel.cors.request(
        method: 'GET'
        url: @getOLDFormsPaginationURL options
        onload: (responseJSON) =>
          Backbone.trigger 'fetchOLDFormsEnd'
          if 'items' of responseJSON
            @add @getDativeFormModelsFromOLDObjects(responseJSON.items)
            Backbone.trigger 'fetchOLDFormsSuccess', responseJSON.paginator
          else
            reason = responseJSON.reason or 'unknown'
            Backbone.trigger 'fetchOLDFormsFail',
              "failed to fetch all old forms; reason: #{reason}"
            console.log ["GET request to /forms failed;",
              "reason: #{reason}"].join ' '
        onerror: (responseJSON) =>
          Backbone.trigger 'fetchOLDFormsEnd'
          Backbone.trigger 'fetchOLDFormsFail', 'error in fetching forms'
          console.log 'Error in GET request to /forms'
      )

    # Add (create) an OLD form.
    # POST `<OLD_URL>/forms`
    addOLDForm: (form, options) ->
      form.trigger 'addOLDFormStart'
      FormModel.cors.request(
        method: 'POST'
        url: "#{@getOLDURL()}/forms"
        payload: form.toOLD()
        onload: (responseJSON, xhr) =>
          form.trigger 'addOLDFormEnd'
          if xhr.status is 200
            form.set responseJSON
            form.trigger 'addOLDFormSuccess', form
          else
            errors = responseJSON.errors or {}
            form.trigger 'addOLDFormFail', errors
            for attribute, error of errors
              form.trigger "validationError:#{attribute}", error
            console.log 'POST request to /forms failed (status not 200) ...'
            console.log errors
        onerror: (responseJSON) =>
          form.trigger 'addOLDFormEnd'
          form.trigger 'addOLDFormFail', responseJSON.error
          console.log 'Error in POST request to /forms'
      )

    # Update an OLD form.
    # PUT `<OLD_URL>/forms/<form.id>`
    updateOLDForm: (form, options) ->
      form.trigger 'updateOLDFormStart'
      FormModel.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/forms/#{form.get 'id'}"
        payload: form.toOLD()
        onload: (responseJSON, xhr) =>
          form.trigger 'updateOLDFormEnd'
          if xhr.status is 200
            form.set responseJSON
            form.trigger 'updateOLDFormSuccess', form
          else
            errors = responseJSON.errors or {}
            error = responseJSON.error or ''
            form.trigger 'updateOLDFormFail', error, form
            for attribute, error of errors
              form.trigger "validationError:#{attribute}", error
            console.log 'PUT request to /forms failed (status not 200) ...'
            console.log errors
        onerror: (responseJSON) =>
          form.trigger 'updateOLDFormEnd'
          form.trigger 'updateOLDFormFail', responseJSON.error
          console.log 'Error in PUT request to /forms'
      )

    # Destroy an OLD form.
    # DELETE `<OLD_URL>/forms/<form.id>`
    destroyOLDForm: (form, options) ->
      Backbone.trigger 'destroyOLDFormStart'
      FormModel.cors.request(
        method: 'DELETE'
        url: "#{@getOLDURL()}/forms/#{form.get 'id'}"
        onload: (responseJSON, xhr) =>
          Backbone.trigger 'destroyOLDFormEnd'
          if xhr.status is 200
            @remove form
            Backbone.trigger 'destroyOLDFormSuccess', form
          else
            error = responseJSON.error or 'No error message provided.'
            Backbone.trigger 'destroyOLDFormFail', error
            console.log "DELETE request to /forms/#{form.get 'id'} failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          Backbone.trigger 'destroyOLDFormEnd'
          error = responseJSON.error or 'No error message provided.'
          Backbone.trigger 'destroyOLDFormFail', error
          console.log "Error in DELETE request to /forms/#{form.get 'id'}
            (onerror triggered)."
      )

    ############################################################################
    # Helpers
    ############################################################################

    getFetchAllFieldDBFormsURL: ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}/_design/pages/_view/datums_chronological"

    getOLDURL: ->
      globals.applicationSettings.get('activeServer').get 'url'

    # Return a URL for requesting a page of forms from an OLD web service.
    # GET parameters control pagination and ordering.
    getOLDFormsPaginationURL: (options) ->
      "#{@getOLDURL()}/forms?\
        page=#{options.page}&\
        items_per_page=#{options.itemsPerPage}"

    # Return a URL for requesting a page of forms from an OLD web service.
    # GET parameters control pagination and ordering.
    # ORDERING: DESC BY ID
    getOLDFormsPaginationURL_: (options) ->
      "#{@getOLDURL()}/forms?\
        page=#{options.page}&\
        items_per_page=#{options.itemsPerPage}&\
        order_by_model=Form&\
        order_by_attribute=id&\
        order_by_direction=desc"

    # Return an array of `FormModel` instances built from FieldDB objects.
    getDativeFormModelsFromFieldDBObjects: (responseJSON) ->
      (new FormModel()).fieldDB2dative(o) for o in responseJSON.rows

    # Return an array of `FormModel` instances built from OLD objects.
    getDativeFormModelsFromOLDObjects: (responseJSON) ->
      (new FormModel()).old2dative(o) for o in responseJSON

