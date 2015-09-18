define [
  'backbone'
  './base'
  './servers'
  './active-server'
  './../templates/application-settings'
], (Backbone, BaseView, ServersView, ActiveServerView,
  applicationSettingsTemplate) ->

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsTemplate

    events:
      'click button.all-settings': 'showOnlySettingsList'
      'click .big-button.servers': 'showServersInterface'
      'click .big-button.appearance': 'showAppearanceInterface'
      'click .big-button.server-settings': 'showServerSettingsInterface'
      'click .jquery-theme-image-container': 'changeJQueryUITheme'
      'click .application-settings-help': 'applicationSettingsHelp'
      'keydown .big-button': 'keydownBigButton'
      'keydown .jquery-theme-image-container': 'keydownJQueryThemeImageContainer'
      'selectmenuchange select[name=activeServer]': 'setModelFromGUI'

    # Tell the Help dialog to open itself and search for "application settings"
    # and scroll to the Xth match. WARN: this is brittle because if the help
    # HTML changes, then the Xth match may not be what we want....
    applicationSettingsHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "application settings"
        scrollToIndex: 1
      )

    setModelFromGUI: ->
      # We don't want to change the active server if we are logged in with it.
      if not @loggedIn()
        selectedActiveServerId = @$('select[name=activeServer]').val()
        activeServer = @model.get('servers').get selectedActiveServerId
        @model.set 'activeServer', activeServer
      @serversView.setCollectionFromGUI()
      # @model.set 'activeJQueryUITheme', @$('select[name=css-theme]').val()
      @model.save()

    keydownBigButton: (event) ->
      if event.which is 13
        @$(event.currentTarget).click()

    keydownJQueryThemeImageContainer: (event) ->
      if event.which is 13
        @$(event.currentTarget).click()

    initialize: ->
      @serversView = new ServersView
        collection: @model.get('servers')
        serverTypes: @model.get('serverTypes')
        bodyVisible: true
      @activeServerView = new ActiveServerView
        model: @model
        tooltipPosition:
          my: "right-100 center"
          at: "left center"
          collision: "flipfit"
        width: 500

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @listenTo Backbone, 'activateServer', @activateServer
      @listenTo Backbone, 'removeServerView', @setModelFromGUI
      @delegateEvents()

    activateServer: (id) ->
      @$('select[name=activeServer]')
        .val(id)
        .selectmenu('refresh')
      @setModelFromGUI()

    # Change the jQuery UI CSS Theme
    changeJQueryUITheme: (event) ->
      try
        themeName =
          (x for x in event.currentTarget.className.split(/\s+/) \
          when @utils.startsWith(x, 'theme-'))[0][6...]
      catch
        console.log 'Error occured while attempting to to change the jQuery
          theme'
        return
      @$('.jquery-theme-image-container')
        .removeClass 'ui-state-highlight'
      @$(event.currentTarget).addClass 'ui-state-highlight'
      @model.set 'activeJQueryUITheme', themeName
      @model.save()
      Backbone.trigger 'applicationSettings:changeTheme'

    showSettingsList: ->
      @$('.application-settings-big-buttons').show()

    hideSettingsList: ->
      @$('.application-settings-big-buttons').hide()

    showInterfaceContainer: ->
      @$('.application-settings-interfaces').show()

    hideInterfaceContainer: ->
      @$('.application-settings-interfaces').hide()

    hideInterfaces: ->
      @$('.application-settings-interface').hide()

    showOnlySettingsList: ->
      @hideInterfaceContainer()
      @hideAllSettingsButton()
      @showSettingsList()

    hideAllSettingsButton: ->
      @$('button.all-settings').hide()

    showAllSettingsButton: ->
      @$('button.all-settings').show()

    showOnlyInterfaces: ->
      @hideSettingsList()
      @showAllSettingsButton()
      @showInterfaceContainer()

    showServersInterface: ->
      @showOnlyInterfaces()
      @hideInterfaces()
      @$('.servers-interface').show()

    showAppearanceInterface: ->
      @showOnlyInterfaces()
      @hideInterfaces()
      @$('.appearance-interface').show()

    showServerSettingsInterface: ->
      @showOnlyInterfaces()
      @hideInterfaces()
      @$('.server-settings-interface').show()

    render: (taskId) ->
      @html()
      @renderServersView()
      @renderActiveServerView()
      @matchHeights()
      @guify()
      @listenToEvents()
      Backbone.trigger 'longTask:deregister', taskId
      @fixRoundedBorders()
      @$('.application-settings-interfaces').hide()
      @hideAllSettingsButton()
      @$('.big-button').first().focus()
      @$('#dative-page-body').scroll => @closeAllTooltips()
      @

    renderServersView: ->
      @serversView.setElement @$('div.servers-collection').first()
      @serversView.render()
      @rendered @serversView

    renderActiveServerView: ->
      @activeServerView.setElement @$('div.active-server').first()
      @activeServerView.render()
      @rendered @activeServerView

    html: ->
      try
        activeJQueryUIThemeHumanReadable =
          (x for x in @model.get('jQueryUIThemes') \
          when x[0] is @model.get('activeJQueryUITheme'))[0][1]
      catch
        activeJQueryUIThemeHumanReadable =
          @model.get('activeJQueryUITheme')

      params = _.extend(
        {
          headerTitle: 'Application Settings'
          activeJQueryUIThemeHumanReadable: activeJQueryUIThemeHumanReadable
          loggedIn: @loggedIn()
        },
        @model.attributes
      )
      @$el.html @template(params)

    loggedIn: -> @model.get 'loggedIn'

    guify: ->
      @$('.big-button')
        .css 'border-color', @constructor.jQueryUIColors().defBo
        .attr 'tabindex', 0
        .tooltip()
      @$('.button-container-left button,.button-container-right button')
        .button()
        .tooltip()
      @$('.jquery-theme-image-container')
        .css 'border-color', @constructor.jQueryUIColors().defBo
        .tooltip position: @tooltipPositionLeft('-20')


  # Application Settings View PREVIOUS
  # ----------------------------------
  #
  # Components of this should be reused in the new application settings ...

  class ApplicationSettingsView_PREVIOUS extends BaseView

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
      @hideAllSettingsButton()
      @$('.big-button').first().focus()
      @

    html: ->
      params = _.extend(
        {headerTitle: 'Application Settings'},
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
        selectedActiveServerId = @$('select[name=activeServer]').val()
        activeServer = @model.get('servers').get selectedActiveServerId
        @model.set 'activeServer', activeServer
      @serversView.setCollectionFromGUI()
      # @model.set 'activeJQueryUITheme', @$('select[name=css-theme]').val()
      @model.save()

    guify: ->

      @$('button').button().attr('tabindex', 0)

      # Main Page GUIfication

      @$('button.edit').button({icons: {primary: 'ui-icon-pencil'}, text:
        false})
      @$('button.save').button({icons: {primary: 'ui-icon-disk'}, text: false})

      @$('div#dative-page-body').first().scroll => @closeAllTooltips()

      @selectmenuify()
      @hoverStateFieldDisplay() # make data display react to focus & hover
      @tabindicesNaught() # active elements have tabindex=0

      @$('div.server-config-widget-body').hide()


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

      @setModelFromGUI()
      Backbone.trigger 'applicationSettings:changeTheme'

      ###
      #themeName = @$(event.target).find(':selected').val()
      themeName = @model.get 'activeJQueryUITheme'
      # TODO: this URL stuff should be in model
      newJQueryUICSSURL = "http://code.jquery.com/ui/1.11.2/themes/#{themeName}/jquery-ui.min.css"
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
      ###

      # Remaining TODOs:
      # 1. persist theme settings to localhost
      # 2. create a default in application settings model
      # 3. disable this feature when there is no Internet connection
      # 4. focus highlight doesn't match on login dialog (probably because it
      #    should be re-rendered after theme change)
      # 5. Gap between rounded borders and container fill. See
      #    http://w3facility.org/question/jquery-ui-how-to-remove-gap-at-each-rounded-corner-of-accordions/

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

  ApplicationSettingsView

