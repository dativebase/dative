define [
  'backbone'
  './base'
  './servers'
  './active-server'
  './../templates/application-settings'
  'perfectscrollbar'
], (Backbone, BaseView, ServersView, ActiveServerView, applicationSettingsTemplate) ->

  # Application Settings View
  # -------------------------

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsTemplate

    events:
      'keyup input': 'setModelFromGUI'
      'selectmenuchange select[name=activeServer]': 'setModelFromGUI'
      'click': 'setModelFromGUI'
      'focus input': 'scrollToFocusedInput'
      'focus button': 'scrollToFocusedInput'
      'selectmenuchange select[name=css-theme]': 'changeTheme'
      'focus button, input, .ui-selectmenu-button': 'rememberFocusedElement'
      # BUG: if you scroll to a selectmenu you've just clicked on, the select
      # dropdown will be left hanging in the place where you originally
      # clicked it. So I've disabled "scroll-to-focus" for selectmenus for now.
      #'focus .ui-selectmenu-button': 'scrollToFocusedInput'

    initialize: ->
      @focusedElementIndex = null
      @serversView = new ServersView
        collection: @model.get('servers')
        serverTypes: @model.get('serverTypes')
      @activeServerView = new ActiveServerView
        model: @model
        tooltipPosition:
          my: "right-100 center"
          at: "left center"
          collision: "flipfit"

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo Backbone, 'activateServer', @activateServer
      @listenTo Backbone, 'removeServerView', @setModelFromGUI
      @delegateEvents()

    activateServer: (id) ->
      @$('select[name=activeServer]')
        .val(id)
        .selectmenu('refresh')
      @setModelFromGUI()

    render: (taskId) ->
      @html()
      @renderServersView()
      @renderActiveServerView()
      @matchHeights()
      @guify()
      @setFocus()
      @listenToEvents()
      Backbone.trigger 'longTask:deregister', taskId
      @fixRoundedBorders()
      @

    html: ->
      params = _.extend(
        {headerTitle: 'Application Settings', themes: @jQueryUIThemes},
        @model.attributes
      )
      @$el.html @template(params)

    renderServersView: ->
      @serversView.setElement @$('li.server-config-container').first()
      @serversView.render()
      @rendered @serversView

    renderActiveServerView: ->
      @activeServerView.setElement @$('li.active-server').first()
      @activeServerView.render()
      @rendered @activeServerView

    loggedIn: -> @model.get 'loggedIn'

    setModelFromGUI: ->
      # We don't want to change the active server if we are logged in with it.
      if not @loggedIn()
        @model.set 'activeServer', @$('select[name=activeServer]').val()
      @serversView.setCollectionFromGUI()
      @model.save()

    guify: ->

      @$('button').button().attr('tabindex', 0)

      # Main Page GUIfication

      @$('button.edit').button({icons: {primary: 'ui-icon-pencil'}, text:
        false})
      @$('button.save').button({icons: {primary: 'ui-icon-disk'}, text: false})

      @perfectScrollbar()

      @selectmenuify()
      @hoverStateFieldDisplay() # make data display react to focus & hover
      @tabindicesNaught() # active elements have tabindex=0

      @$('div.server-config-widget-body').hide()

    perfectScrollbar: ->
      @$('div#dative-page-body').first()
        .perfectScrollbar()
        .scroll => @closeAllTooltips()

    # The special `onClose` event is called by `close` in base.coffee upon close
    onClose: ->
      @$('div#dative-page-body').first().unbind 'scroll'

    selectmenuify: ->
      @$('select[name=css-theme]').selectmenu
        width: 540

    # Make active elements have tabindex=0
    hoverStateFieldDisplay: ->
      @$('div.dative-input-display')
        .mouseover(->
          $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .focus(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .mouseout(->
          $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
        .blur(->
          $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('button, select, input, textarea, div.dative-input-display,
        span.ui-selectmenu-button')
        .css("border-color", @constructor.jQueryUIColors().defBo)
        .attr('tabindex', 0)

    setFocus: ->
      if @focusedElementIndex
        @focusLastFocusedElement()
      else
        @focusFirstElement()

    ############################################################################
    # Change jQueryUI CSS Theme stuff
    ############################################################################

    # Change the jQuery UI CSS Theme
    changeTheme: (event) ->

      # This is harder than it might at first seem.
      # Method:
      # 1. get new CSS URL from selectmenu
      # 2. remove the current jQueryUI CSS <link>
      # 3. add a new jQueryUI CSS <link> with the new URL in its `href`
      # 4. ***CRUCIAL:*** when <link> `load` event fires, we ...
      # 5. get `BaseView.constructor` to refresh its `_jQueryUIColors`, which ...
      # 6. triggers a Backbone event indicating that the jQueryUI theme has changed, which ...
      # 7. causes `MainMenuView` to re-render.
      #
      # WARN: works for me on Mac with FF, Ch & Sa. Unsure of
      # cross-platform/browser support. May want to do feature detection and
      # employ a mixture of strategies 1-4.

      newJQueryUICSSURL = @$(event.target).find(':selected').val()
      $jQueryUILinkElement = $('#jquery-ui-css')
      $jQueryUILinkElement.remove()
      $jQueryUILinkElement.attr href: newJQueryUICSSURL
      linkHTML = $jQueryUILinkElement.get(0).outerHTML
      $('#font-awesome-css').after linkHTML
      outerCallback = =>
        innerCallback = =>
          Backbone.trigger 'application-settings:jQueryUIThemeChanged'
        @constructor.refreshJQueryUIColors innerCallback
      @listenForLinkOnload outerCallback

      # Still TODO:
      # 1. persist theme settings to localhost
      # 2. create a default in application settings model
      # 3. disable this feature when there is no Internet connection
      # 4. focus highlight doesn't match on login dialog (probably because it
      #    should be re-rendered after theme change)
      # 5. Gap between rounded borders and container fill. See
      #    http://w3facility.org/question/jquery-ui-how-to-remove-gap-at-each-rounded-corner-of-accordions/

    jQueryUIThemes: [
      ['ui-lightness', 'UI lightness']
      ['ui-darkness', 'UI darkness']
      ['smoothness', 'Smoothness']
      ['start', 'Start']
      ['redmond', 'Redmond']
      ['sunny', 'Sunny']
      ['overcast', 'Overcast']
      ['le-frog', 'Le Frog']
      ['flick', 'Flick']
      ['pepper-grinder', 'Pepper Grinder']
      ['eggplant', 'Eggplant']
      ['dark-hive', 'Dark Hive']
      ['cupertino', 'Cupertino']
      ['south-street', 'South Street']
      ['blitzer', 'Blitzer']
      ['humanity', 'Humanity']
      ['hot-sneaks', 'Hot Sneaks']
      ['excite-bike', 'Excite Bike']
      ['vader', 'Vader']
      ['dot-luv', 'Dot Luv']
      ['mint-choc', 'Mint Choc']
      ['black-tie', 'Black Tie']
      ['trontastic', 'Trontastic']
      ['swanky-purse', 'Swanky Purse']
    ]

    ############################################################################
    # Four strategies for detecting that a new CSS <link> has loaded.
    # See http://www.phpied.com/when-is-a-stylesheet-really-loaded/
    ############################################################################

    # strategy #1
    listenForLinkOnload: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      link.onload = -> callback()

    # strategy #2
    addEventListenerToLink: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      eventListener = -> callback()
      if link.addEventListener
        link.addEventListener 'load', eventListener, false

    # strategy #3
    listenForReadyStateChange: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      link.onreadystatechange = ->
        state = link.readyState
        if state is 'loaded' or state is 'complete'
          link.onreadystatechange = null
          callback()

    # strategy #4
    checkForChangeInDocumentStyleSheets: (callback) ->
      cssnum = document.styleSheets.length
      func = ->
        if document.styleSheets.length > cssnum
          callback()
          clearInterval ti
      ti = setInterval func, 10

