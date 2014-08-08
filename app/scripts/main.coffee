#/*global require*/
'use strict'

require.config

  shim:
    lodash:
      exports: '_'
    backbone: ["lodash", "jquery"]
    jqueryui: ['jquery']
    superfish: ['jquery']
    supersubs: ['jquery']
    multiselect: ['jquery', 'jqueryui']
    backboneindexeddb: ['backbone']
    jqueryelastic: ['jquery']

  paths:
    jquery: '../bower_components/jquery/dist/jquery'
    backbone: '../bower_components/backbone/backbone'
    lodash: '../bower_components/lodash/dist/lodash'
    underscore: '../bower_components/lodash/dist/lodash.underscore'
    backboneindexeddb:
      '../bower_components/indexeddb-backbonejs-adapter/backbone-indexeddb'
    bootstrap: '../bower_components/sass-bootstrap/dist/js/bootstrap'
    text: '../bower_components/requirejs-text/text'
    jqueryui: '../bower_components/jqueryui/jquery-ui'
    superfish: '../bower_components/superfish/dist/js/superfish'
    igt: 'jquery-extensions/igt'
    jqueryuicolors: 'jquery-extensions/jqueryui-colors'
    sfjquimatch: 'jquery-extensions/superfish-jqueryui-match'
    # Supersubs plugin removed in v1.6 of superfish. See
    # https://github.com/joeldbirch/superfish.
    supersubs: '../bower_components/superfish/dist/js/supersubs'
    multiselect: '../bower_components/multiselect/js/jquery.multi-select'
    jqueryelastic: '../bower_components/jakobmattsson-jquery-elastic/jquery.elastic.source'
    #betterelastictextarea: '../bower_components/better-elastic-textarea/dist/better-elastic-textarea'

require [
    'views/app',
    'routes/router'
    'backboneindexeddb'
    'multiselect'
    'jqueryelastic'
  ], (AppView, Workspace) ->
    new Workspace()
    Backbone.history.start()
    window.debugMode = false
    $ ->
      new AppView()

