define [
  './base'
  './../models/file'
  './../templates/file-data'
], (BaseView, FileModel, fileDataTemplate) ->

  # File Data View
  # ------------------
  #
  # A view for displaying the file data (e.g., the image, audio, video, pdf) of
  # a file model/resource.

  class FileDataView extends BaseView

    template: fileDataTemplate
    className: 'file-data-widget dative-widget-center
      dative-shadowed-widget ui-widget ui-widget-content ui-corner-all'

    initialize: (options) ->
      # If `@parentFile` is `true`, this view will have a different interface,
      # one that accords with the display of a subinterval-referencing file's
      # parent file data.
      @parentFile = options.parentFile or false
      @headerTitle = if @parentFile then @model.get('filename') else 'File Data'
      @resourceName = options?.resourceName or ''
      @activeServerType = @getActiveServerType()
      @setState()
      @listenToEvents()

    setState: ->
      @MIMEType = @getMIMEType()
      @type = @getType()
      @canPlayVideo = @getCanPlayVideo()

    getMIMEType: ->
      if @model.get 'parent_file'
        @model.get('parent_file').MIME_type
      else if @model.get 'url'
        @utils.getMIMEType @model.get('url')
      else
        @model.get 'MIME_type'

    getType: ->
      try
        @MIMEType.split('/')[0]
      catch
        null

    listenToEvents: ->
      super
      @listenTo @model, 'fetchFileDataEnd', @fetchFileDataEnd
      @listenTo @model, 'fetchFileDataFail', @fetchFileDataFail
      @listenTo @model, 'fetchFileDataSuccess', @fetchFileDataSuccess
      @listenTo @model, 'change', @checkIfFileDataChanged
      @listenTo @model, 'fileDataChanged', @fileDataChanged
      # If we are displaying the data of a subinterval-referencing file, we
      # have to control the cursor start and end positions.
      if @model.get('parent_file')
        @listenTo @model, 'change:start', @fixIfOutOfInterval
        @listenTo @model, 'change:end', @fixIfOutOfInterval
        @$(@type)
          .bind 'loadedmetadata', ((event) => @getDuration event)
          .bind 'timeupdate', ((event) => @fixIfOutOfInterval event)
      # If we are displaying a parent file's data, we want to show the position
      # of the cursor in real seconds as the cursor moves.
      if @parentFile
        @$(@type)
          .bind 'timeupdate', ((event) => @showTimeInSeconds event)

    showTimeInSeconds: (event) ->
      @$('span.current-time-seconds')
        .text "#{event.currentTarget.currentTime.toFixed(2)}s"

    getDuration: (event) ->
      @duration = event.currentTarget.duration

    getStart: ->
      modelStart = @model.get 'start'
      if (@utils.type(modelStart) is 'number') and
      modelStart >= 0
        modelStart
      else
        0

    getEnd: ->
      modelEnd = @model.get 'end'
      if (@utils.type(modelEnd) is 'number') and
      modelEnd <= @duration
        modelEnd
      else
        @duration

    fixIfOutOfInterval: ->
      end = @getEnd()
      start = @getStart()
      mediaElement = @$(@type).first().get(0)
      if mediaElement.currentTime >= end or
      mediaElement.currentTime < start
        mediaElement.currentTime = start
        mediaElement.pause()

    checkIfFileDataChanged: ->
      if @model.hasChanged 'filename' or
      @model.hasChanged 'size' or
      @model.hasChanged 'parent_file'
        @fileDataChanged()
      else if @model.hasChanged 'url'
        url = @model.get 'url'
        if url and @utils.isValidURL url
          @fileDataChanged()

    fileDataChanged: ->
      @setState()
      @render()
      if (@MIMEType is 'application/pdf') or
      (@type is 'audio') or
      (@type is 'video' and @canPlayVideo) or
      (@type is 'image') or
      @embedCode
        if not @$el.is(':visible') then @trigger 'fileDataView:show'
      else
        if @$el.is(':visible') then @trigger 'fileDataView:hide'

    events:
      'click button.hide-file-data-widget':         'hideSelf'
      'click button.deselect-parent-file':          'deselectAsParentFile'
      'click button.set-current-position-to-start': 'setCurrentPositionToStart'
      'click button.set-current-position-to-end':   'setCurrentPositionToEnd'
      'keydown':                                    'keydown'

    setCurrentPositionToStart: ->
      try
        @trigger 'setAttribute', 'start',
          @$(@type).first().get(0).currentTime

    setCurrentPositionToEnd: ->
      try
        @trigger 'setAttribute', 'end',
          @$(@type).first().get(0).currentTime

    onClose: ->
      try
        super
      if @model.get('parent_file')
        @$(@type).unbind 'timeupdate'
        @$(@type).unbind 'loadedmetadata'
      else if @parentFile
        @$(@type).unbind 'timeupdate'

    deselectAsParentFile: ->
      @trigger 'deselectAsParentFile'

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    requestFileData: ->
      @spin()
      @listenToOnce @model, 'fetchFileDataFailNoReduced',
        @requestFileDataLossless
      @model.fetchFileData()

    requestFileDataLossless: ->
      @model.fetchFileData false

    fetchFileDataEnd: ->
      @stopSpin()

    fetchFileDataFail: (error) ->
      console.log "unable to fetch file data: #{error}"

    fetchFileDataSuccess: (fileData) ->
      type = @model.get 'MIME_type'
      blob = new Blob([fileData], {type: type})
      url = URL.createObjectURL(blob)
      if type is 'audio/x-wav' then type = 'audio/wav'
      audioHTML_ = "<audio controls>
        <source src='#{url}' type='#{type}'>
        Your browser does not support the audio tag.
      </audio>"
      audioHTML = "<audio
        controls='controls'
        src='#{url}'
        type='#{type}'>
      </audio>"
      @$('div.file-data-container').html audioHTML

    # Try to get <HTML> for embedding an externally-hosted resource. 
    getEmbedCode: ->
      url = @model.get 'url'      # If there is no URL, there is no embed code.
      if not url then return null
      result = null
      dataURL = youTubeId = vimeoId = null
      dataURL = @getDataURL url
      if dataURL
        result = @getEmbedCodeData dataURL
      else
        youTubeId = @getYouTubeId url
        if youTubeId
          result = @getEmbedCodeYouTube youTubeId
        else
          vimeoId = @getVimeoId url
          if vimeoId
            result = @getEmbedCodeVimeo vimeoId
      result

    # If `url` is a video we like to play, then return it; otherwise return
    # `null`. TODO: allow for audio files being served like this too...
    getDataURL: (url) ->
      extension = @utils.getExtension url
      if extension of @utils.extensions then url else null

    getEmbedCodeData: (dataURL) ->
      try
        @_getEmbedCodeData dataURL
      catch
        'Sorry, this file cannot be displayed.'

    _getEmbedCodeData: (dataURL) ->
      MIMEType = @utils.getMIMEType dataURL
      if MIMEType is 'application/pdf'
        "<object class='file-data-pdf'
          data='#{dataURL}'
          type='#{MIMEType}'
          name='#{@model.get('name')}'
          >#{@model.get('name')}</object>"
      else
        "<video class='file-data-video ui-corner-bottom' controls>
            <source
                src='#{dataURL}'
                type='#{MIMEType}'>
            Your browser does not support the video tag.
        </video>"

    # See http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url
    getYouTubeId: (url) ->
      regex = /// ^ .* (
          youtu.be\/
        | youtube(-nocookie)?.com\/ (
              v\/
            | .*u\/\w\/
            | embed\/
            | .*v=
          )
        ) (
          [\w-]{11}
        ) .* ///
      match = url.match regex
      if match and match[4] and match[4].length is 11
        match[4]
      else
        null

    # See http://stackoverflow.com/a/11660798/992730
    getVimeoId: (url) ->
      regex = /// ^ .*
        (vimeo\.com\/)
        (
            (channels\/[A-z]+\/)
          | (groups\/[A-z]+\/videos\/)
        ) ?
        ([0-9]+) ///
      match = url.match regex
      if match and match[5]
        match[5]
      else
        null

    getIframeDimensions: ->
      if @model.get 'id'
        ['700px', '393.75px']
      else
        ['770.266px', '433.275px']

    getEmbedCodeYouTube: (youTubeId) ->
      [width, height] = @getIframeDimensions()
      "<iframe
        class='embed-code'
        src='http://www.youtube.com/embed/#{youTubeId}'
        type='text/html'
        width='#{width}'
        height='#{height}'
        frameborder='0'
        seamless
        webkitallowfullscreen
        mozallowfullscreen
        allowFullScreen></iframe>"

    getEmbedCodeVimeo: (vimeoId) ->
      [width, height] = @getIframeDimensions()
      "<iframe
        class='embed-code'
        src='https://player.vimeo.com/video/#{vimeoId}?badge=0'
        width='#{width}'
        height='#{height}'
        frameborder='0'
        seamless
        webkitallowfullscreen
        mozallowfullscreen
        allowfullscreen></iframe>"

    html: ->
      # TODO: make sure that the lossy file does get embedded if it exists,
      # i.e., create tests and mocks where the backend OLD has made reduced
      # file copies.
      undownloadable = false
      fileURL = @model.getFetchFileDataURL()
      name = @model.get 'filename'
      MIMEType = @MIMEType
      reducedURL = @model.getFetchFileDataURL true
      lossyFilename = @model.get 'lossy_filename'
      if @model.get 'url'
        name = @model.get 'name'
        fileURL = @model.get 'url'
        if not @utils.getMIMEType(@model.get('url')) then undownloadable = true
      else if @model.get 'parent_file'
        parentFileModel = new FileModel(@model.get('parent_file'))
        fileURL = parentFileModel.getFetchFileDataURL()
        reducedURL = parentFileModel.getFetchFileDataURL true
        MIMEType = parentFileModel.get 'MIME_type'
        lossyFilename = parentFileModel.get 'lossy_filename'
        name = @model.get 'name'
      else if (not @model.get('id'))
        if @model.get 'base64_encoded_file'
          fileURL = "data:#{@model.get('MIME_type')};base64,\
            #{@model.get('base64_encoded_file')}"
        else if @model.get 'blobURL'
          fileURL = @model.get 'blobURL'
      @embedCode = @getEmbedCode()
      context =
        parentFile: @parentFile
        name: name
        containerStyle: @getContainerStyle()
        embedCode: @embedCode
        fileURL: fileURL
        undownloadable: undownloadable
        reducedURL: reducedURL
        lossyFilename: lossyFilename
        canPlayVideo: @canPlayVideo
        MIMEType: MIMEType
        type: @type
        resourceName: @resourceName
        headerTitle: @headerTitle
        activeServerType: @activeServerType
      @$el.html @template(context)

    guify: ->
      @fixRoundedBorders() # defined in BaseView
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo
      @$('button').button()
      @tooltipify()
      @fixImageRoundedBorders()

    getCanPlayVideo: ->
      if @type is 'video'
        testEl = document.createElement 'video'
        '' isnt testEl.canPlayType(@MIMEType)
      else
        false

    # I'm rounding the bottom borders off the images. However, because of how
    # nested rounded borders work, we have to change the <img> tag's bottom
    # borders to a fractional number that is calculated given the border radius
    # value of its parent <div>.
    fixImageRoundedBorders: ->
      if @type is 'image'
        bodyRadius = @$('.dative-widget-body').css 'border-bottom-left-radius'
        newRadius = "#{(parseInt(bodyRadius) * 0.91666).toFixed 2}px"
        @$('.file-data-image')
          .css
            'border-bottom-left-radius': newRadius
            'border-bottom-right-radius': newRadius

    # If this is a PDF ('application/pdf'), then we alter the height of the
    # enclosing <div> so that the PDF will be displayed at a readable size.  #
    getContainerStyle: ->
      if @type is 'application'
        newHeight = $(window).height() * 0.7
        "style='height: #{newHeight}px; overflow: auto;' "
      else if @type is 'video'
        "style='overflow: auto;' "
      else if @type is 'audio'
        "style='padding: 1em;' "
      else
        ''

    tooltipify: ->
      @$('.button-container-right .dative-tooltip')
        .tooltip position: @tooltipPositionRight('+20')
      @$('.button-container-left .dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

    # The resource super-view will handle this hiding.
    hideSelf: -> @trigger "fileDataView:hide"

    # ESC hides the file data widget
    keydown: (event) ->
      event.stopPropagation()
      switch event.which
        when 27
          @stopEvent event
          @hideSelf()

    spinnerOptions: (top='50%', left='-170%') ->
      options = super
      options.top = top
      options.left = left
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: (selector='.spinner-container', top='50%', left='-170%') ->
      @$(selector).spin @spinnerOptions(top, left)

    stopSpin: (selector='.spinner-container') ->
      @$(selector).spin false

