'use strict'
LIVERELOAD_PORT = 35729
SERVER_PORT = 9000
lrSnippet = require('connect-livereload')({port: LIVERELOAD_PORT})
mountFolder = (connect, dir) ->
  connect.static(require('path').resolve(dir))

# # Globbing
# for performance reasons we're only matching one level down:
# 'test/spec/{,*/}*.js'
# use this if you want to match all subfolders:
# 'test/spec/**/*.js'
# templateFramework: 'lodash'

module.exports = (grunt) ->

  # show elapsed time at the end
  require('time-grunt') grunt

  # load all grunt tasks
  require('load-grunt-tasks') grunt

  # configurable paths
  yeomanConfig = app: 'app', dist: 'dist'

  grunt.initConfig

    yeoman: yeomanConfig

    watch:
      options:
        nospawn: true
        livereload: true
      coffee:
        files: ['<%= yeoman.app %>/scripts/{,*/}*.coffee']
        tasks: ['coffee:dist']
      coffeeTest:
        #files: ['test/spec/{,*/}*.coffee']
        files: ['test/**/*.coffee']
        tasks: ['coffee:test']
      compass:
        files: ['<%= yeoman.app %>/styles/{,*/}*.{scss,sass}']
        tasks: ['compass']
      livereload:
        options:
          livereload: grunt.option('livereloadport') || LIVERELOAD_PORT
        files: [
          '<%= yeoman.app %>/*.html'
          '{.tmp,<%= yeoman.app %>}/styles/{,*/}*.css'
          '{.tmp,<%= yeoman.app %>}/scripts/{,*/}*.js'
          '<%= yeoman.app %>/images/{,*/}*.{png,jpg,jpeg,gif,webp}'
          '<%= yeoman.app %>/scripts/templates/*.{ejs,mustache,hbs}'
          'test/spec/**/*.js'
        ]
      jst:
        files: ['<%= yeoman.app %>/scripts/templates/*.ejs']
        tasks: ['jst']
      test:
        files: ['<%= yeoman.app %>/scripts/{,*/}*.js', 'test/spec/**/*.js']
        tasks: ['test:true']

    docco:
      src: ['.doctmp/*.coffee']
      #src: ['<%= yeoman.app %>/scripts/**/*.coffee']
      options:
        output: 'docs/'

    connect:
      options:
        port: grunt.option('port') || SERVER_PORT
        # change this to '0.0.0.0' to access the server from outside
        hostname: 'localhost'
      livereload:
        options:
          middleware: (connect) ->
            [
              lrSnippet,
              mountFolder(connect, '.tmp')
              mountFolder(connect, yeomanConfig.app)
            ]
      test:
        options:
          port: 9001
          middleware: (connect) ->
            [
              lrSnippet
              mountFolder(connect, '.tmp')
              mountFolder(connect, 'test')
              mountFolder(connect, yeomanConfig.app)
            ]
      dist:
        options:
          middleware: (connect) ->
            [mountFolder(connect, yeomanConfig.dist)]

    open:
      server:
        path: 'http://localhost:<%= connect.options.port %>'
      test:
        path: 'http://localhost:<%= connect.test.options.port %>'
        #app: 'firefox'

    clean:
      dist: ['.tmp', '<%= yeoman.dist %>/*']
      server: '.tmp'
      doctmp: '.doctmp'
      docs: 'docs'

    jshint: 
      options:
        jshintrc: '.jshintrc'
        reporter: require('jshint-stylish')
      all: [
        'Gruntfile.js'
        '<%= yeoman.app %>/scripts/{,*/}*.js'
        '!<%= yeoman.app %>/scripts/vendor/*'
        'test/spec/{,*/}*.js'
      ]

    mocha:
      all:
        options:
          log: true
          run: false # default: true
          reporter: 'Spec'
          testtimeout: 90000
          urls: ['http://localhost:<%= connect.test.options.port %>/index.html']

    coffee:
      dist:
        files: [
          # rather than compiling multiple files here you should
          # require them into your main .coffee file
          expand: true
          cwd: '<%= yeoman.app %>/scripts'
          src: '{,*/}*.coffee'
          dest: '.tmp/scripts'
          ext: '.js'
        ]
      test:
        files: [
          expand: true
          #cwd: 'test/spec' # original
          cwd: 'test'
          #src: '{,*/}*.coffee' # original
          src: '**/*.coffee'
          dest: '.tmp/spec' # original
          #dest: '.tmp'
          ext: '.js'
        ]

    # see http://brianflove.com/2014/04/18/web-development-automation-gruntfile-using-coffeescript/
    # see https://www.npmjs.org/package/grunt-coffeelint
    # see http://www.coffeelint.org/
    coffeelint:
      app:
        src: '<%= yeoman.app %>/scripts/**/*.coffee'
      options:
        no_tabs:
          level: 'ignore'
        indentation:
          level: 'ignore' # Unfortunately, coffeelint and requirejs's define callbacks don't play well together
        no_trailing_whitespace:
          level: 'error'
        no_trailing_semicolons:
          level: 'error'
        no_plusplus:
          level: 'warn'
        no_implicit_parens:
          level: 'ignore'
        max_line_length:
          level: 'ignore'

    compass:
      options:
        sassDir: '<%= yeoman.app %>/styles',
        cssDir: '.tmp/styles',
        imagesDir: '<%= yeoman.app %>/images',
        javascriptsDir: '<%= yeoman.app %>/scripts',
        fontsDir: '<%= yeoman.app %>/styles/fonts',
        importPath: '<%= yeoman.app %>/bower_components',
        relativeAssets: true
      dist: {},
      server:
        options:
          debugInfo: true

    requirejs:
      dist:
        # Options: https://github.com/jrburke/r.js/blob/master/build/example.build.js
        options:
          # `name` and `out` is set by grunt-usemin
          baseUrl: '.tmp/scripts'
          optimize: 'none'
          paths:
            'templates': '../../.tmp/scripts/templates'
            'jquery': '../../<%= yeoman.app %>/bower_components/jquery/dist/jquery'
            'jqueryui': '../../<%= yeoman.app %>/bower_components/jqueryui/jquery-ui'
            'superfish': '../../<%= yeoman.app %>/bower_components/superfish/dist/js/superfish'
            'supersubs': '../../<%= yeoman.app %>/bower_components/superfish/dist/js/supersubs'
            #'underscore': '../../<%= yeoman.app %>/bower_components/lodash/dist/lodash'
            'lodash': '../../<%= yeoman.app %>/bower_components/lodash/dist/lodash'
            'underscore': '../../<%= yeoman.app %>/bower_components/underscore/underscore'
            'backbone': '../../<%= yeoman.app %>/bower_components/backbone/backbone'
            'igt': '../../<%= yeoman.app %>/scripts/jquery-extensions/igt'
            'jqueryuicolors': '../../<%= yeoman.app %>/scripts/jquery-extensions/jqueryui-colors'
            'sfjquimatch': '../../<%= yeoman.app %>/scripts/jquery-extensions/superfish-jqueryui-match'
          # TODO: Figure out how to make sourcemaps work with grunt-usemin
          # https://github.com/yeoman/grunt-usemin/issues/30
          #generateSourceMaps: true
          # required to support SourceMaps
          # http://requirejs.org/docs/errors.html#sourcemapcomments
          preserveLicenseComments: false
          useStrict: true
          wrap: true
          #uglify2: {} # https://github.com/mishoo/UglifyJS2
          #
    useminPrepare:
      html: '<%= yeoman.app %>/index.html'
      options: 
        dest: '<%= yeoman.dist %>'

    usemin:
      html: ['<%= yeoman.dist %>/{,*/}*.html']
      css: ['<%= yeoman.dist %>/styles/{,*/}*.css']
      options: 
        dirs: ['<%= yeoman.dist %>']

    imagemin:
      dist:
        files: [
          expand: true
          cwd: '<%= yeoman.app %>/images'
          src: '{,*/}*.{png,jpg,jpeg}'
          dest: '<%= yeoman.dist %>/images'
        ]

    cssmin:
      dist:
        files:
          '<%= yeoman.dist %>/styles/main.css': [
            '.tmp/styles/{,*/}*.css'
            '<%= yeoman.app %>/styles/{,*/}*.css'
            '<%= yeoman.app %>/bower_components/jqueryui/themes/le-frog/jquery-ui.css'
          ]

    htmlmin:
      dist:
        options: {}
        ###
          removeCommentsFromCDATA: true,
          # https://github.com/yeoman/grunt-usemin/issues/44
          #collapseWhitespace: true,
          collapseBooleanAttributes: true,
          removeAttributeQuotes: true,
          removeRedundantAttributes: true,
          useShortDoctype: true,
          removeEmptyAttributes: true,
          removeOptionalTags: true
        ###
        files: [
          expand: true,
          cwd: '<%= yeoman.app %>',
          src: '*.html',
          dest: '<%= yeoman.dist %>'
        ]

    copy:
      dist:
        files: [
          expand: true
          dot: true
          cwd: '<%= yeoman.app %>'
          dest: '<%= yeoman.dist %>'
          src: [
            '*.{ico,txt}'
            '.htaccess'
            'images/{,*/}*.{webp,gif}'
            'styles/fonts/{,*/}*.*'
            'bower_components/sass-bootstrap/fonts/*.*'
          ]
        ]
      docco:
        files: [
            expand: true
            cwd: '<%= yeoman.app %>/scripts/' # src/modules/'
            src: ['**/*.coffee']
            dest: '.doctmp/' # dev/js/'
            rename: (dest, src) ->
              return dest + src.replace(/\//g, '.')
          ,
            expand: true
            cwd: 'test/'
            src: ['!bower_components/*.coffee', '**/*.coffee']
            dest: '.doctmp/'
            rename: (dest, src) ->
              return dest + 'test.' + src.replace(/\//g, '.')
        ]

    bower:
      all:
        rjsConfig: '<%= yeoman.app %>/scripts/main.js'

    jst:
      options:
        amd: true
      compile:
        files:
          '.tmp/scripts/templates.js': ['<%= yeoman.app %>/scripts/templates/*.ejs']

    rev:
      dist:
        files:
          src: [
            '<%= yeoman.dist %>/scripts/{,*/}*.js'
            '<%= yeoman.dist %>/styles/{,*/}*.css',
            '<%= yeoman.dist %>/images/{,*/}*.{png,jpg,jpeg,gif,webp}',
            '/styles/fonts/{,*/}*.*',
            'bower_components/sass-bootstrap/fonts/*.*'
          ]

  grunt.registerTask 'createDefaultTemplate', ->
    grunt.file.write '.tmp/scripts/templates.js', 'this.JST = this.JST || {}'

  grunt.registerTask 'server', (target) ->
    grunt.log.warn 'The `server` task has been deprecated. Use `grunt serve` to start a server.'
    grunt.task.run ['serve' + (target ? ':' + target : '')]

  grunt.registerTask 'serve', (target) ->
    if target is 'dist'
      return grunt.task.run ['build', 'open:server', 'connect:dist:keepalive']

    if target is 'test'
      return grunt.task.run [
        'clean:server'
        'coffee'
        'createDefaultTemplate'
        'jst'
        'compass:server'
        'connect:test'
        'open:test'
        'watch'
      ]

    grunt.task.run [
      'clean:server'
      'coffee:dist'
      'createDefaultTemplate'
      'jst'
      'compass:server'
      'connect:livereload'
      'open:server'
      'watch'
    ]

  grunt.registerTask 'coffeeDist', ['coffee:dist']

  grunt.registerTask 'test', (isConnected) ->
    isConnected = Boolean(isConnected)
    testTasks = [
      'clean:server'
      'coffee'
      'createDefaultTemplate'
      'jst'
      'compass'
      'connect:test'
      'mocha'
    ]
    if not isConnected
      grunt.task.run testTasks
    else
      # already connected so not going to connect again, remove the connect:test task
      testTasks.splice testTasks.indexOf('connect:test'), 1
      grunt.task.run testTasks

  grunt.registerTask 'build', [
    'clean:dist'
    'coffee'
    'createDefaultTemplate'
    'jst'
    'compass:dist'
    'useminPrepare'
    'requirejs'
    'imagemin'
    'htmlmin'
    'concat'
    'cssmin'
    'uglify'
    'copy'
    'rev'
    'usemin'
  ]

  grunt.registerTask 'default', ['jshint', 'test', 'build']

  grunt.registerTask 'lint', 'coffeelint'

  grunt.registerTask 'docs', ['clean:docs', 'clean:doctmp', 'copy:docco', 'docco', 'clean:doctmp']

