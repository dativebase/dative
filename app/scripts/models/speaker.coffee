define ['./resource'], (ResourceModel) ->

  # Speaker Model
  # -------------
  #
  # A Backbone model for Dative speakers.

  class SpeakerModel extends ResourceModel

    resourceName: 'speaker'

    ############################################################################
    # Speaker Schema
    ############################################################################

    defaults: ->
      first_name: ''           # Max 255 chars, can't be empty.
      last_name: ''            # Max 255 chars, can't be empty.
      dialect: ''              # Max 255 chars,
      markup_language: ''      # One of "Markdown" or "reStructuredText",
                               # defaults to "reStructuredText".
      page_content: ''         # A string of lightweight markup.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null                 # The relational id given to the speaker model.
      datetime_modified: ''    # When the speaker was last modified.
      html: ''                 # HTML generated from the speaker-supplied
                               # markup.

    editableAttributes: [
      'first_name'
      'last_name'
      'dialect'
      'markup_language'
      'page_content'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'first_name' then @requiredString
        when 'last_name' then @requiredString
        else null

