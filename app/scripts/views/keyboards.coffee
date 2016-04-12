define [
  './resources'
  './keyboard'
  './../collections/keyboards'
  './../models/keyboard'
  './../utils/globals'
], (ResourcesView, KeyboardView, KeyboardsCollection,
  KeyboardModel, globals) ->

  # Keyboards View
  # --------------
  #
  # Displays a collection of keyboards for browsing, with pagination. Also
  # contains a model-less `KeyboardView` instance for creating new keyboards
  # within the browse interface.

  class KeyboardsView extends ResourcesView

    resourceName: 'keyboard'
    resourceView: KeyboardView
    resourcesCollection: KeyboardsCollection
    resourceModel: KeyboardModel

    # Overriding this super-class method prevents the annoying scrolling that
    # happens otherwise when you click on a keyboard key.
    resourceFocused: (event) ->
      if @$(event.target).hasClass 'dative-resource-widget'
        @rememberFocusedElement event

