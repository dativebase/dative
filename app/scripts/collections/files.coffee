define [
  './resources'
  './../models/file'
], (ResourcesCollection, FileModel) ->

  # Files Collection
  # ----------------
  #
  # Holds models for files. Note that because of the particular way in which
  # OLD web services handle the uploading of large files---i.e., the request
  # must be multipart/form-data, not JSON---we make some customizations here.

  class FilesCollection extends ResourcesCollection

    resourceName: 'file'
    model: FileModel

    addResource: (resource, options={}) ->
      options.monitorProgress = true
      options.progressModel = resource
      if resource.get('dative_file_type') is 'storedOnTheServer' and
      resource.get('base64_encoded_file') is ''
        @addFileAsMultipartFormData resource, options
      else
        super resource, options

    getResourceForServerCreateMultipartFormData: (resource) ->
      formData = new FormData()
      for attribute of resource.attributes
        value = resource.get attribute
        if attribute in ['elicitor', 'speaker']
          if value is undefined then value = ''
        formData.append attribute, value
      formData

    addFileAsMultipartFormData: (resource, options) ->
      resource.trigger "add#{@resourceNameCapitalized}Start"
      payload = @getResourceForServerCreateMultipartFormData resource
      monitorProgress = options.monitorProgress or false
      progressModel = options.progressModel or null
      @model.cors.request(
        monitorProgress: monitorProgress
        progressModel: progressModel
        contentType: "multipart/form-data;" # This isn't actually used, it's just a signal to `CORS` that this is multipart/form-data...
        method: 'POST'
        url: @getAddResourceURL resource
        payload: payload
        onload: (responseJSON, xhr) =>
          @addResourceOnloadHandler resource, responseJSON, xhr, payload
        onerror: (responseJSON) =>
          resource.trigger "add#{@resourceNameCapitalized}End"
          resource.trigger "add#{@resourceNameCapitalized}Fail",
            responseJSON.error, resource
          console.log "Error in POST request to /#{@getServerSideResourceName()}"
      )

