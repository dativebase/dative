define [
  './base'
  './../templates/file-data'
], (BaseView, fileDataTemplate) ->

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
      @resourceName = options?.resourceName or ''
      @MIMEType = @model.get 'MIME_type'
      @type = @getType()
      @canPlayVideo = @getCanPlayVideo()
      @activeServerType = @getActiveServerType()
      @listenToEvents()

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

    events:
      'click button.hide-file-data-widget': 'hideSelf'
      #'click button.file-data-download':    ''
      'keydown':                            'keydown'

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

    html: ->
      # TODO: make sure that the lossy file does get embedded if it exists,
      # i.e., create tests and mocks where the backend OLD has made reduced
      # file copies.
      context =
        name: @model.get 'filename'
        containerStyle: @getContainerStyle()
        URL: @model.getFetchFileDataURL()
        reducedURL: @model.getFetchFileDataURL true
        lossyFilename: @model.get 'lossy_filename'
        canPlayVideo: @canPlayVideo
        MIMEType: @MIMEType
        type: @type
        resourceName: @resourceName
        headerTitle: 'File Data'
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

