define [
  './base'
  './../templates/selected-resource-wrapper'
  './../utils/globals'
], (BaseView, selectedResourceWrapperTemplate, globals) ->

  # Selected Resource Wrapper View
  # ------------------------------
  #
  # This view is used to wrap a resource view that is representing a model that
  # has been selected by the user. This is needed by both the
  # `ResourcesSelectViaSearchInputView` and the
  # `ResourceSelectViaSearchInputView`.

  class SelectedResourceWrapperView extends BaseView

    initialize: (@selectedResourceViewClass, @selectedResourceViewParams) ->
      @selectedResourceView =
        new @selectedResourceViewClass @selectedResourceViewParams
      @model = @selectedResourceView.model

    template: selectedResourceWrapperTemplate

    render: ->
      @$el.html @template(@selectedResourceViewParams)
      @buttonify()
      @renderResourceSelectedView()
      @$('.dative-tooltip').tooltip position: @tooltipPositionLeft('-200')
      @listenToEvents()
      @

    renderResourceSelectedView: ->
      @$('.selected-resource-container').html @selectedResourceView.render().el
      @rendered @selectedResourceView

    events:
      'click .deselect': 'deselect'

    deselect: -> @trigger 'deselect', @


