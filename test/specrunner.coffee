#/*global require*/
'use strict'

require.config

  shim:
    jquery:
      exports: '$'
    lodash:
      exports: '_'
    FieldDB:
      exports: 'FieldDB'
    backbone:
      exports: 'Backbone'
      deps: ['lodash', 'jquery']
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


    igt: '../scripts/jquery-extensions/igt'
    jqueryuicolors: '../scripts/jquery-extensions/jqueryui-colors'
    tagit: 'jquery-extensions/tag-it'
    sfjquimatch: '../scripts/jquery-extensions/superfish-jqueryui-match'
    # Supersubs plugin removed in v1.6 of superfish. See
    # https://github.com/joeldbirch/superfish.
    supersubs: '../bower_components/superfish/dist/js/supersubs'


    multiselect: '../bower_components/multiselect/js/jquery.multi-select'
    jqueryelastic: '../bower_components/jakobmattsson-jquery-elastic/jquery.elastic.source'
    autosize: '../bower_components/autosize/jquery.autosize'

    spin: '../bower_components/spin.js/spin'
    jqueryspin: '../bower_components/spin.js/jquery.spin'
    FieldDB: '../bower_components/fielddb/fielddb'
    backbonerelational: '../bower_components/backbone-relational/backbone-relational'
    backbonelocalstorage: '../bower_components/backbone.localStorage/backbone.localStorage'

specs = [
  # These specs are old and at this point are probably only good as a reference
  # for how mocha/chai/sinon works.

  #'spec/models/form.js' # FAILING
  #'spec/collections/forms.js' # FAILING
  #'spec/utils/indexeddb-utils.js'
  #'spec/views/base.js'
  #'spec/views/app.js'
  #'spec/views/mainmenu.js'
  #'spec/views/application-settings.js'
  #'spec/views/login-dialog.js'
  #'spec/models/application-settings.js'
  #'spec/models/base.js'

  # These are the good specs ...
  'spec/utils/utils.js'
  'spec/views/form.js'
]

require specs, ->
    mocha.run()

