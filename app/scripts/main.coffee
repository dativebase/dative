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
    perfectscrollbar: ['jquery']
    superfish: ['jquery']
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
    superfish: 'jquery-extensions/superfish'
    #superfish: '../bower_components/superfish/dist/js/superfish'
    #superfish: 'jquery-extensions/superfish/dist/js/superfish'
    igt: 'jquery-extensions/igt'
    jqueryuicolors: 'jquery-extensions/jqueryui-colors'
    sfjquimatch: 'jquery-extensions/superfish-jqueryui-match'
    # Supersubs plugin removed in v1.6 of superfish. See
    # https://github.com/joeldbirch/superfish.
    supersubs: 'jquery-extensions/supersubs'
    #supersubs: '../bower_components/superfish/dist/js/supersubs'
    #supersubs: 'jquery-extensions/superfish/dist/js/supersubs'
    multiselect: '../bower_components/multiselect/js/jquery.multi-select'
    jqueryelastic: '../bower_components/jakobmattsson-jquery-elastic/jquery.elastic.source'
    #betterelastictextarea: '../bower_components/better-elastic-textarea/dist/better-elastic-textarea'
    spin: '../bower_components/spin.js/spin'
    jqueryspin: '../bower_components/spin.js/jquery.spin'
    perfectscrollbar: '../bower_components/perfect-scrollbar/src/perfect-scrollbar'
    # FieldDB: '../bower_components/fielddb/fielddb'
    backbonerelational: '../bower_components/backbone-relational/backbone-relational'
    backbonelocalstorage: '../bower_components/backbone.localStorage/backbone.localStorage'

require [
    'views/app',
    'routes/router'
    # 'FieldDB'
    #'backboneindexeddb'
    'multiselect'
    'jqueryelastic'
    'jqueryuicolors'
    'sfjquimatch'
    'jqueryspin'
  ], (AppView, Workspace) ->
    new Workspace()
    Backbone.history.start()
    window.debugMode = false

    # Overriding FieldDB's logging hooks to do nothing
    # FieldDB.FieldDBObject.verbose = () -> {}
    # FieldDB.FieldDBObject.debug = () -> {}
    # FieldDB.FieldDBObject.todo = () -> {}

    # Overriding FieldDB's notification hooks
    FieldDB.FieldDBObject.bug = (message) ->
      console.log "TODO show some visual contact us or open a bug report in a seperate window using probably http://jqueryui.com/dialog/#default " , message
      # $("#dialog").dialog(message);
      run = () ->
        window.open("https://docs.google.com/forms/d/18KcT_SO8YxG8QNlHValEztGmFpEc4-ZrjWO76lm0mUQ/viewform")
      setTimeout(run, 1000)

    FieldDB.FieldDBObject.warn = (message, message2, message3, message4) ->
      console.log "TODO show some visual thing here using the app view using something like http://www.erichynds.com/examples/jquery-notify/" , message

    FieldDB.FieldDBObject.confirm = (message, optionalLocale) ->
      console.log "TODO show some visual thing here using the app view using something like http://jqueryui.com/dialog/#modal-confirmation" , message
      # deferred = FieldDB.Q.defer(),
      # self = this;

      # $(function() {
      #   $( "#dialog-confirm" ).dialog({
      #     resizable: false,
      #     height:140,
      #     modal: true,
      #     buttons: {
      #       message: function() {
      #         $( this ).dialog( "close" );
      #         deferred.resolve({
      #           message: message,
      #           optionalLocale: optionalLocale,
      #           response: true
      #           });
      #         },
      #         Cancel: function() {
      #           $( this ).dialog( "close" );
      #           deferred.reject({
      #             message: message,
      #             optionalLocale: optionalLocale,
      #             response: false
      #             });
      #         }
      #       }
      #       });
      #   });

    $ ->
      new AppView()

