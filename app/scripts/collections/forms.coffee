define [
  'backbone',
  './../models/form'
  './../utils/utils'
], (Backbone, FormModel, utils) ->

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
              "failed to fetch all fielddb forms; reason: #{reason}"
            console.log ["request to datums_chronological failed;",
              "reason: #{reason}"].join ' '
        onerror: (responseJSON) =>
          Backbone.trigger 'fetchAllFieldDBFormsEnd'
          Backbone.trigger 'fetchAllFieldDBFormsFail', 'error in fetching all
            fielddb forms'
          console.log 'Error in request to datums_chronological'
      )

    # Fetch OLD Forms
    # GET `<OLD_URL>/forms
    fetchOLDForms: ->
      Backbone.trigger 'fetchOLDFormsStart'
      FormModel.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/forms"
        onload: (responseJSON) =>
          Backbone.trigger 'fetchOLDFormsEnd'
          if utils.type(responseJSON) is 'array'
            @add @getDativeFormModelsFromOLDObjects(responseJSON)
            Backbone.trigger 'fetchOLDFormsSuccess'
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
      url = @applicationSettings.get 'baseDBURL'
      pouchname = @activeFieldDBCorpus.get 'pouchname'
      "#{url}/#{pouchname}/_design/pages/_view/datums_chronological"

    getOLDURL: -> @applicationSettings.get('activeServer').get 'url'

    # Return an array of `FormModel` instances built from FieldDB objects.
    getDativeFormModelsFromFieldDBObjects: (responseJSON) ->
      (new FormModel()).fieldDB2dative(o) for o in responseJSON.rows

    # Return an array of `FormModel` instances built from OLD objects.
    getDativeFormModelsFromOLDObjects: (responseJSON) ->
      (new FormModel()).old2dative(o) for o in responseJSON

