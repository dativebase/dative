#/*global require*/
'use strict'

require.config

  shim:
    jquery:
      exports: '$'
    lodash:
      exports: '_'
    # FieldDB:
    #   exports: 'FieldDB'
    backbone:
      exports: 'Backbone'
      deps: ['lodash', 'jquery']
    #jqueryui: ['../bower_components/jquery/dist/jquery']
    jqueryui: ['jquery']
    # backboneindexeddb: ['backbone']
    multiselect: ['jquery', 'jqueryui']
    jqueryelastic: ['jquery']
    autosize: ['jquery']
    superfish: ['jquery']
    superclick: ['jquery']
    supersubs: ['jquery']
    backbonerelational: ['backbone']
    backbonelocalstorage: ['backbone']

  paths:
    jquery: '../bower_components/jquery/dist/jquery'
    backbone: '../bower_components/backbone/backbone'
    lodash: '../bower_components/lodash/dist/lodash'
    underscore: '../bower_components/lodash/dist/lodash.underscore'
    # backboneindexeddb:
    #   '../bower_components/indexeddb-backbonejs-adapter/backbone-indexeddb'
    bootstrap: '../bower_components/sass-bootstrap/dist/js/bootstrap'
    text: '../bower_components/requirejs-text/text'
    jqueryui: '../bower_components/jqueryui/jquery-ui'
    superfish: '../bower_components/superfish/dist/js/superfish'
    superclick: '../bower_components/superclick/dist/js/superclick'
    #superfish: '../bower_components/superfish/dist/js/superfish'
    #superfish: 'jquery-extensions/superfish/dist/js/superfish'
    igt: 'jquery-extensions/igt'
    jqueryuicolors: 'jquery-extensions/jqueryui-colors'
    tagit: 'jquery-extensions/tag-it'
    sfjquimatch: 'jquery-extensions/superfish-jqueryui-match'
    # Supersubs plugin removed in v1.6 of superfish. See
    # https://github.com/joeldbirch/superfish.
    supersubs: '../bower_components/superfish/dist/js/supersubs'
    #supersubs: '../bower_components/superfish/dist/js/supersubs'
    #supersubs: 'jquery-extensions/superfish/dist/js/supersubs'
    multiselect: '../bower_components/multiselect/js/jquery.multi-select'
    jqueryelastic: '../bower_components/jakobmattsson-jquery-elastic/jquery.elastic.source'
    autosize: '../bower_components/autosize/jquery.autosize'
    #betterelastictextarea: '../bower_components/better-elastic-textarea/dist/better-elastic-textarea'
    spin: '../bower_components/spin.js/spin'
    jqueryspin: '../bower_components/spin.js/jquery.spin'
    # FieldDB: '../bower_components/fielddb/fielddb'
    backbonerelational: '../bower_components/backbone-relational/backbone-relational'
    backbonelocalstorage: '../bower_components/backbone.localStorage/backbone.localStorage'

require [
    'views/app'
    'routes/router'
    'multiselect'
    'jqueryelastic'
    'jqueryuicolors'
    'tagit'
    'jqueryspin'
  ], (AppView, Workspace) ->
    window.debugMode = false

    $ ->

      if 'serviceWorker' of navigator
        navigator.serviceWorker.register('/sw.js').then((registration) ->
          # Registration was successful
          console.log 'ServiceWorker registration successful with
            scope: ', registration.scope
        ).catch((err) ->
          # registration failed :(
          console.log 'ServiceWorker registration failed: ', err
        )

      app = new AppView()
      window.onbeforeunload = ->
        app.close()
        window.location.href += window.location.hash
        window.location.reload()

