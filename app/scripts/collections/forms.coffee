define [
    'backbone',
    './../models/form'
    './../models/database'
  ], (Backbone, FormModel, database) ->

  # Forms Collection
  # ----------------
  #
  # Holds models for forms.

  class FormsCollection extends Backbone.Collection

    model: FormModel

    getFetchAllFieldDBFormsURL: ->
      url = @applicationSettings.get 'baseDBURL'
      pouchname = @applicationSettings.get('activeFieldDBCorpus').get('pouchname')
      "#{url}/#{pouchname}/_design/pages/_view/datums_chronological"

    getDativeFormObjects: (responseJSON) ->
      @fieldDBDatum2DativeForm(o) for o in responseJSON.rows

    fieldDBDatum2DativeForm: (fieldDBDatum) ->
      dativeForm = {id: fieldDBDatum.id}
      for datumFieldObject in fieldDBDatum.value.datumFields
        attribute = @datumLabel2FormAttribute datumFieldObject.label
        value = @datumValue2FormValue datumFieldObject.value, datumFieldObject.label
        dativeForm[attribute] = value
      dativeForm

    datumValue2FormValue: (value, label) ->
      switch label
        when 'translation' then [{grammaticality: '', transcription: value}]
        else value

    datumLabel2FormAttribute: (label) ->
      switch label
        when 'utterance' then 'transcription'
        when 'gloss' then 'morphemeGloss'
        when 'morphemes' then 'morphemeBreak'
        when 'judgement' then 'grammaticality'
        when 'translation' then 'translations'
        else label

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
            @add @getDativeFormObjects(responseJSON)
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


    # Backbone-IndexedDB stuff
    database: database
    storeName: 'forms'
    url: 'http://127.0.0.1:5002'

    # Overriding `fetch` (for now...)
    fetch: (options) ->
      @_fakeFetch()
      #@_corsFetch()

    _fakeFetch: ->
      fakeFormModel1 = new @model
        transcription: 'chien'
        translations: [
            transcription: 'dog'
          ,
            transcription: 'hound'
          ,
            transcription: 'wolf'
            grammaticality: '*'
        ]
      fakeFormModel2 = new @model
        transcription: 'chat'
        translations: [transcription: 'cat']
      @set [fakeFormModel1, fakeFormModel2]

    _corsFetch: ->

      # TODO: read this: http://stackoverflow.com/questions/14376295/should-i-simulate-a-cors-options-request-in-sinon-js-or-how-do-i-test-cross-doma

      url = "#{@url}/forms"
      method = 'GET'
      payload = null

      fetchType = 'authenticate'
      if fetchType is 'authenticate'
        url = 'http://127.0.0.1:5000/login/authenticate'
        method = 'POST'
        payload = JSON.stringify(username: 'dative-rest-username', password: 'password')
      else if fetchType is 'forms_new'
        url = 'http://127.0.0.1:5000/forms/new'
      console.log url
      xhr = @model::createCORSRequest method, url
      if not xhr
        throw new Error 'CORS not supported'
      xhr.withCredentials = true
      xhr.send(payload)

      console.log 'I made a request'
      xhr.onload = ->
        console.log 'onload fired'
        responseText = xhr.responseText
        console.log responseText

        # TODO: process the response.

      xhr.onerror = ->
        console.log 'onerror: there was an error!'

      xhr.onloadstart = ->
        console.log 'onloadstart: the request has started'

      xhr.onabort = ->
        console.log 'onabort: the request has been aborted. For instance, by
          invoking the abort() method.'

      xhr.onprogress = ->
        console.log 'onprogress: while loading and sending data.'

      xhr.ontimeout = ->
        console.log 'ontimeout: author-specified timeout has passed before the
          request could complete.'

      xhr.onloadend = ->
        console.log 'onloadend: the request has completed (either in success
          or failure).'

