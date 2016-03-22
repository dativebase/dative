define [
    './resource'
    './../utils/globals'
  ], (ResourceModel, globals) ->

  # Page Model
  # ----------
  #
  # A Backbone model for Dative pages.

  class PageModel extends ResourceModel

    resourceName: 'page'

    ############################################################################
    # Page Schema
    ############################################################################

    defaults: ->
      name: ''                 # <string> Required, unique among page names,
                               # max 255 chars.
      heading: ''              # <string> max 255 chars.
      markup_language: ''      # One of "Markdown" or "reStructuredText",
                               # defaults to "reStructuredText".
      content: ''              # a string of lightweight markup, defining the
                               # page content.
      html: ''                 # HTML generated from the user-supplied markup.
      id: null                 # <int> relational id
      datetime_modified: ""    # <string>  (datetime resource was last
                               # modified; format and construction same as
                               # `datetime_entered`.)

    editableAttributes: [
      'name'
      'heading'
      'markup_language'
      'content'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

    # If the home page is deleted, we need to tell the application settings
    # about that.
    destroyResourceOnloadHandler: (responseJSON, xhr) ->
      if xhr.status is 200 and responseJSON.name == 'home'
        globals.applicationSettings.set 'homepage', null
        globals.applicationSettings.save()
      super responseJSON, xhr

