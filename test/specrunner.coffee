#/*global require*/

require.config

  shim:
    jquery:
      exports: '$'
    lodash:
      exports: '_'
    backbone:
      exports: 'Backbone'
      deps: ['lodash', 'jquery']
    jqueryui: ['jquery']
    backboneindexeddb: ['backbone']
    multiselect: ['jquery', 'jqueryui']
    jqueryelastic: ['jquery']
    jqueryuicolors: ['jquery', 'jqueryui']
    superfish: ['jquery']
    supersubs: ['jquery']

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
    igt: '../scripts/jquery-extensions/igt'
    jqueryuicolors: '../scripts/jquery-extensions/jqueryui-colors'
    sfjquimatch: '../scripts/jquery-extensions/superfish-jqueryui-match'
    # Supersubs plugin removed in v1.6 of superfish. See
    # https://github.com/joeldbirch/superfish.
    supersubs: '../bower_components/superfish/dist/js/supersubs'
    multiselect: '../bower_components/multiselect/js/jquery.multi-select'
    jqueryelastic: '../bower_components/jakobmattsson-jquery-elastic/jquery.elastic.source'
    spin: '../bower_components/spin.js/spin'
    jqueryspin: '../bower_components/spin.js/jquery.spin'

specs = [
  #'spec/models/form.js'
  #'spec/collections/forms.js'
  #'spec/utils/indexeddb-utils.js'
  'spec/views/base.js'
  'spec/views/app.js'
  'spec/views/mainmenu.js'
  'spec/views/application-settings.js'
  #'spec/models/base.js'
  #'spec/models/form.js'
]

require specs, ->
    mocha.run()

