define [
  'jquery',
  'lodash',
  'backbone'
  'views/base'
], ($, _, Backbone, BaseView) ->

  # Base Page View
  # --------------
  #
  # This is the view that all Dative views should inherit from, assuming
  # they are pages, i.e., they have #old-page-header and #old-page-body divs

  # The DOM element for summarizing the pages of and OLD app
  class BasePageView extends BaseView

    tagName:  'div'
    template: JST['app/scripts/templates/basepage.ejs']
    initialized: false

    initialize: ->
      # Get the jQuery UI colors
      @initialized = true

    render: ->
      @$el.html @template()
      @matchHeights()

    # Page Views contain a header div (#old-page-header) and a body div
    # (#old-page-body).  matchHeights keeps the body height constant
    # relative to its parent's height, even when window resizes.
    matchHeights: ->
      pageBody = $('#old-page-body')[0]
      parent = $(pageBody).parent()
      pageHeader = $('#old-page-header')
      margin = parseInt $(pageBody).css('margin')
      hasVerticalScrollBar = @hasVerticalScrollBar
      $(pageBody).css 'height',
        parent.innerHeight() - pageHeader.outerHeight() - (margin * 2)
      if hasVerticalScrollBar pageBody
        $(pageBody).css 'padding-right', 10
      $(window).resize ->
        $(pageBody).css 'height',
          parent.innerHeight() - pageHeader.outerHeight() - (margin * 2)
        if hasVerticalScrollBar pageBody
          $(pageBody).css 'padding-right', 10

    # Return true if elm has a vertical scrollbar
    hasVerticalScrollBar: (elm) ->
      if elm.clientHeight < elm.scrollHeight then true else false

