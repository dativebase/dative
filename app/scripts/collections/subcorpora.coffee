define [
  'backbone',
  './../models/subcorpus'
  './../utils/utils'
  './../utils/globals'
], (Backbone, SubcorpusModel, utils, globals) ->

  # Subcorpora Collection
  # ---------------------
  #
  # Holds models for subcorpora.
  #
  # Note: and OLD "corpus" ("corpora") is a Dative "subcorpus" ("subcorpora").
  # This terminological change is made in order to avoid confusion with FieldDB
  # corpora.

  class SubcorporaCollection extends Backbone.Collection

    model: SubcorpusModel
    url: 'fake-url'

    # Fetch Subcorpora (with pagination, if needed)
    # GET `<OLD_URL>/corpora?page=x&items_per_page=y
    # See http://online-linguistic-database.readthedocs.org/en/latest/interface.html#get-resources
    fetchSubcorpora: (options) ->
      Backbone.trigger 'fetchSubcorporaStart'
      SubcorpusModel.cors.request(
        method: 'GET'
        url: @getSubcorporaPaginationURL options
        onload: (responseJSON) =>
          Backbone.trigger 'fetchSubcorporaEnd'
          if 'items' of responseJSON
            @add @getDativeSubcorpusModelsFromOLDObjects(responseJSON.items)
            Backbone.trigger 'fetchSubcorporaSuccess', responseJSON.paginator
          else
            reason = responseJSON.reason or 'unknown'
            Backbone.trigger 'fetchSubcorporaFail',
              "failed to fetch all OLD corpora; reason: #{reason}"
            console.log "GET request to /corpora failed; reason: #{reason}"
        onerror: (responseJSON) =>
          Backbone.trigger 'fetchSubcorporaEnd'
          Backbone.trigger 'fetchSubcorporaFail', 'error in fetching corpora'
          console.log 'Error in GET request to /corpora'
      )

    # Add (create) an OLD corpus.
    # POST `<OLD_URL>/corpora`
    addSubcorpus: (subcorpus, options) ->
      subcorpus.trigger 'addSubcorpusStart'
      SubcorpusModel.cors.request(
        method: 'POST'
        url: "#{@getOLDURL()}/corpora"
        payload: subcorpus.toOLD()
        onload: (responseJSON, xhr) =>
          subcorpus.trigger 'addSubcorpusEnd'
          if xhr.status is 200
            subcorpus.set responseJSON
            subcorpus.trigger 'addSubcorpusSuccess', subcorpus
          else
            errors = responseJSON.errors or {}
            error = errors.error
            subcorpus.trigger 'addSubcorpusFail', error
            for attribute, error of errors
              subcorpus.trigger "validationError:#{attribute}", error
            console.log 'POST request to /corpora failed (status not 200) ...'
            console.log errors
        onerror: (responseJSON) =>
          subcorpus.trigger 'addSubcorpusEnd'
          subcorpus.trigger 'addSubcorpusFail', responseJSON.error, subcorpus
          console.log 'Error in POST request to /corpora'
      )

    # Update an OLD corpus.
    # PUT `<OLD_URL>/corpora/<corpus.id>`
    updateSubcorpus: (subcorpus, options) ->
      subcorpus.trigger 'updateSubcorpusStart'
      SubcorpusModel.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/corpora/#{subcorpus.get 'id'}"
        payload: subcorpus.toOLD()
        onload: (responseJSON, xhr) =>
          subcorpus.trigger 'updateSubcorpusEnd'
          if xhr.status is 200
            subcorpus.set responseJSON
            subcorpus.trigger 'updateSubcorpusSuccess'
          else
            errors = responseJSON.errors or {}
            error = responseJSON.error
            subcorpus.trigger 'updateSubcorpusFail', error, subcorpus
            for attribute, error of errors
              subcorpus.trigger "validationError:#{attribute}", error
            console.log 'PUT request to /corpora failed (status not 200) ...'
            console.log errors
        onerror: (responseJSON) =>
          subcorpus.trigger 'updateSubcorpusEnd'
          subcorpus.trigger 'updateSubcorpusFail', responseJSON.error, subcorpus
          console.log 'Error in PUT request to /corpora'
      )

    ############################################################################
    # Helpers
    ############################################################################

    getOLDURL: ->
      globals.applicationSettings.get('activeServer').get 'url'

    # Return a URL for requesting a page of corpora from an OLD web service.
    # GET parameters control pagination and ordering.
    # Note: other possible parameters: `order_by_model`, `order_by_attribute`,
    # and `order_by_direction`.
    getSubcorporaPaginationURL: (options) ->
      if options.page and options.itemsPerPage
        "#{@getOLDURL()}/corpora?\
          page=#{options.page}&\
          items_per_page=#{options.itemsPerPage}"
      else
        "#{@getOLDURL()}/corpora"

    # Return an array of `SubcorpusModel` instances built from OLD objects.
    getDativeSubcorpusModelsFromOLDObjects: (responseJSON) ->
      (new SubcorpusModel(o) for o in responseJSON)

