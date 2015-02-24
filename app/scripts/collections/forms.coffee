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

