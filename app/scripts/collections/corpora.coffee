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
                'There was an error creating corpus “#{newCorpusTitle}”.
                 Please report this.'
          , (responseJSON) ->
            Backbone.trigger 'newCorpusEnd'
            Backbone.trigger 'newCorpusFail', responseJSON.userFriendlyErrors.join ' '

      , () =>
        delete @originalMessage
        Backbone.trigger 'newCorpusEnd'
      


