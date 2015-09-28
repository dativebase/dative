define [
    'backbone',
    './../models/corpus'
  ], (Backbone, CorpusModel) ->

  # Corpora Collection
  # ------------------
  #
  # Holds models for FieldDB corpora.

  class CorporaCollection extends Backbone.Collection

    model: CorpusModel

    # Create a new corpus.
    # POST `<AuthServiceURL>/newcorpus`
    newCorpus: (newCorpusName) ->
      Backbone.trigger 'newCorpusStart', newCorpusName
      payload =
        authUrl: @applicationSettings.get?('activeServer')?.get?('url')
        username: @applicationSettings.get?('username')
        password: @applicationSettings.get?('password') # TODO use confirm identity event instead
        serverCode: @applicationSettings.get?('activeServer')?.get?('serverCode')
        newCorpusName: newCorpusName
      CorpusModel.cors.request(
        method: 'POST'
        timeout: 10000
        url: "#{payload.authUrl}/newcorpus"
        payload: payload
        onload: (responseJSON) =>
          Backbone.trigger 'newCorpusEnd'
          if responseJSON.corpusadded
            if responseJSON.corpus
              corpusObject = responseJSON.corpus
              corpusObject.applicationSettings = @applicationSettings
              @unshift corpusObject
              Backbone.trigger 'newCorpusSuccess', newCorpusName
            else
              Backbone.trigger 'newCorpusFail',
                ["There was an error creating corpus “#{newCorpusName}”.",
                 "This name is probably already taken.",
                 "Try a different one."].join ' '
              console.log responseJSON.userFriendlyErrors[0]
          else
            Backbone.trigger 'newCorpusFail', "Request to create corpus failed: `corpusadded` not truthy."
            console.log 'Failed request to /newcorpus: `corpusadded` not truthy.'
        onerror: (responseJSON) ->
          Backbone.trigger 'newCorpusEnd'
          Backbone.trigger 'newCorpusFail', "Request to create corpus failed with an error."
          console.log 'Failed request to /newcorpus: error.'
        ontimeout: ->
          Backbone.trigger 'newCorpusEnd'
          Backbone.trigger 'newCorpusFail', "Request to create corpus failed: request timed out."
          console.log 'Failed request to /newcorpus: timed out.'
      )

