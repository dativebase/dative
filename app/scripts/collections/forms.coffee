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

    getResourcesPaginationURL: (options) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super options
        when 'FieldDB' then @getFieldDBFormsPaginationURL options

    getFieldDBFormsPaginationURL: (options) ->
      url = @getFetchAllFieldDBFormsURL()
      if options.page and options.page isnt 0 and options.itemsPerPage
        skip = (options.page - 1) * options.itemsPerPage
        "#{url}?limit=#{options.itemsPerPage}&skip=#{skip}"
      else
        "#{url}?limit=#{options.itemsPerPage}"

    getFetchAllFieldDBFormsURL: ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}/_design/pages/_view/datums_chronological"

    fetchResourcesOnloadHandler: (responseJSON) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super responseJSON
        when 'FieldDB' then @fetchResourcesOnloadHandlerFieldDB responseJSON

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

    # Return an array of `FormModel` instances built from FieldDB objects.
    getDativeFormModelsFromFieldDBObjects: (responseJSON) ->
      (new FormModel()).fieldDB2dative(o) for o in responseJSON.rows

