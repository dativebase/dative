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
    newCorpus: (newCorpusTitle) ->
      Backbone.trigger 'newCorpusStart', newCorpusTitle

      @applicationSettings
      .get('fieldDBApplication')
      .prompt('We need to make sure this is you. Confirm your password to continue.')
      .then (dialog) => 
        delete @originalMessage
        payload =
          authUrl: @applicationSettings.get?('activeServer')?.get?('url')
          username: @applicationSettings.get?('username')
          password: dialog.response
          title: newCorpusTitle
        @applicationSettings
          .get('fieldDBApplication')
          .authentication
          .newCorpus(payload)
          .then (fieldDBCorpus) ->
            Backbone.trigger 'newCorpusEnd'
            if fieldDBCorpus
              fieldDBCorpus.applicationSettings = @applicationSettings
              @unshift fieldDBCorpus
              Backbone.trigger 'newCorpusSuccess', newCorpusTitle
            else
              Backbone.trigger 'newCorpusFail',
              ["There was an error creating corpus “#{newCorpusTitle}”.",
                 "This name is probably already taken.",
                 "Try a different one."].join ' '
              console.log responseJSON.userFriendlyErrors[0]
          , (responseJSON) ->
            Backbone.trigger 'newCorpusEnd'
            Backbone.trigger 'newCorpusFail', responseJSON.userFriendlyErrors.join ' '
        # onerror: (responseJSON) ->
        #   Backbone.trigger 'newCorpusEnd'
        #   Backbone.trigger 'newCorpusFail', "Request to create corpus failed with an error."
        #   console.log 'Failed request to /newcorpus: error.'
        # ontimeout: ->
        #   Backbone.trigger 'newCorpusEnd'
        #   Backbone.trigger 'newCorpusFail', "Request to create corpus failed: request timed out."
        #   console.log 'Failed request to /newcorpus: timed out.'
      , () =>
        delete @originalMessage
        Backbone.trigger 'newCorpusEnd'

