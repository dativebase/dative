define [
  './field'
  './form'
  './collection-contents-input'
  './../models/form'
  './../collections/forms'
], (FieldView, FormView, CollectionContentsInputView, FormModel, FormsCollection) ->

  # Collection Contents Field View
  # ------------------------------
  #
  # A view for inputing collection contents values. Like a `ScriptFieldView`
  # except this one allows for a continuous preview of the Collection's
  # contents as they are entered.


  # We don't want our embedded `FormView` instances to have "duplicate" buttons
  # since they don't work (yet) when the form views are not sub-views of a
  # `FormsView` instance.
  class FormViewNoDuplicateAction extends FormView

    excludedActions: ['controls', 'data', 'duplicate']


  class CollectionContentsFieldView extends FieldView

    initialize: (options) ->
      super options

      @formsCollection = new FormsCollection()

      # This regex identifies form references.
      @regex = /form\[(\d+)\]/g

      @previewRendered = false

      @lastContents = ''

      # Maps form ids to the form objects that we have received from the server.
      @formObjects = {}

      @formViews = []

      # Array of all of the form id references (numbers) in our contents value.
      @formIdReferences = []

      # Maps form ids to the `FormModel` instances that we have built from the
      # form objects that we received from the server.
      @formModels = {}

    # Default is to call `set` on the model any time a field input changes.
    events:
      'change':                'setToModel' # fires when multi-select changes
      'input':                 'setToModel' # fires when an input, textarea or date-picker changes
      'selectmenuchange':      'setToModel' # fires when a selectmenu changes
      'menuselect':            'setToModel' # fires when the tags multi-select changes (not working?...)
      'keydown .ms-container': 'multiselectKeydown'
      'keydown textarea, input, .ui-selectmenu-button, .ms-container':
                               'controlEnterSubmit'
      'click .c-contents-preview': 'togglePreview'
      'click .c-contents-refresh': 'refreshPreview'

    # CTRL+ENTER in an input-type element should trigger form submission,
    # except on the contents input, where that should trigger a contents
    # preview refresh.
    controlEnterSubmit: (event) ->
      if event.ctrlKey and event.which is 13
        @stopEvent event
        if @$(event.currentTarget).hasClass 'contents'
          @refreshPreview()
        else
          @trigger 'submit'

    togglePreview: ->
      if @$('div.collection-contents-preview-wrapper').is ':visible'
        @hidePreview()
      else
        @showPreview()

    hidePreview: ->
      @hidePreviewDiv()
      @stretchTextarea()
      #@livePreviewOff()
      @previewVisible = false

    showPreview: ->
      @squeezeTextarea()
      @showPreviewDiv()
      @generatePreview()
      #@livePreviewOn()
      @previewVisible = true
      @forceInsertFormViews = true
      @sendReferencedFormIdsToQueue()

    # Length of time, in seconds, that we wait between refreshings of the
    # preview.
    livePreviewInterval: 3

    # Call `@generatePreview()` at regular intervals. NOTE: use of this method
    # was halted because it consumes too many resources. Instead we let the
    # user manually refresh the preview, as desired.
    livePreviewOn: ->
      @livePreviewId = setInterval(
        (=> @generatePreview()), (@livePreviewInterval * 1000))

    livePreviewOff: ->
      clearInterval @livePreviewId

    showPreviewDiv: ->
      @$('div.collection-contents-preview-wrapper').fadeIn()

    hidePreviewDiv: ->
      @$('div.collection-contents-preview-wrapper').fadeOut()

    refreshPreview: ->
      @generatePreview()
      @forceInsertFormViews = true
      @sendReferencedFormIdsToQueue()

    # Generate the preview of 
    generatePreview: ->
      contents = @$('textarea.contents').first().val()
      if @forceInsertFormViews or contents != @lastContents
        @forceInsertFormViews = false
        @lastContents = contents
        html = contents.replace(@regex, (m, $1) ->
          "<div class=\"form-container\" data-form-id=\"#{$1}\"
            >form #{$1}</div>")
        @$('div.collection-contents-preview').html html
        @insertFormViews()

    # Insert rendered form views into all the places in the contents preview
    # where there is a form reference. The complication here is that we try to
    # reuse form views, if possible.
    insertFormViews: ->
      newFormViews = []
      @$('div.collection-contents-preview .form-container').each((i, e) =>
        $e = @$ e
        formId = Number($e.data 'form-id')
        if formId of @formModels
          model = @formModels[formId]
          if model
            viewIndex = null
            for view, index in @formViews
              if view.model.get('id') == formId
                viewIndex = index
                break
            if viewIndex
              formView = @formViews[viewIndex]
              @formViews.splice viewIndex, 1
            else
              formView = new FormViewNoDuplicateAction(model: model)
            newFormViews.push formView
            $e.addClass 'dative-resource-widget dative-form-object
              dative-paginated-item dative-widget-center ui-corner-all'
            formView.setElement $e
            formView.render()
            @rendered formView
          else
            $e.html "There is no form with id #{formId}"
      )
      for formView in @formViews
        formView.close()
      @formViews = newFormViews

    squeezeTextarea: ->
      @$('textarea.contents').animate({height: "16.5em"}, 300)

    stretchTextarea: ->
      @$('textarea.contents').animate({height: "25em"}, 300)

    guify: ->
      @$('.c-contents-buttons button').button().tooltip()
      @$('div.collection-contents-preview-wrapper')
        .css "border-color", @constructor.jQueryUIColors().defBo
      # This is the case where the resource is taking up the entire appview div.
      if $('#appview').children('.dative-resource-widget').length > 0
        @$('.c-contents-buttons').css left: '18.3em'
      else if @addUpdateType is 'add'
        @$('.c-contents-buttons').css left: '16.5em'

    getFieldLabelContainerClass: ->
      "#{super} top"

    getFieldInputContainerClass: ->
      "#{super} full-width"

    getInputView: ->
      new CollectionContentsInputView @context

    listenToEvents: ->
      super
      @listenTo @model, 'change:contents', @sendReferencedFormIdsToQueue
      @listenTo @model, 'formObjectsChanged', @formObjectsChanged

    # Our parent view is telling us that the form objects referenced in the
    # contents field has changed.
    # FOX
    formObjectsChanged: (@formObjects) ->
      for id, obj of @formObjects
        if id not of @formModels
          if obj
            @formModels[id] = new FormModel(obj, collection: @formsCollection)
          else
            @formModels[id] = null
      if @forceInsertFormViews then @generatePreview()

    # The contents value has changed so we identify any form references that
    # the user has entered (of the form "form[123]") and we trigger an event
    # that causes our parent view to fetch the referenced forms.
    sendReferencedFormIdsToQueue: ->
      @formIdReferences = []
      while match = @regex.exec @model.get('contents')
        @formIdReferences.push Number(match[1])
      @model.trigger 'addReferencedFormsToFetchQueue', @formIdReferences

