define ['./resource'], (ResourceModel) ->

  # User Model
  # ---------------
  #
  # A Backbone model for Dative users.

  class UserModel extends ResourceModel

    resourceName: 'user'

    ############################################################################
    # User Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1027-L1047
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/user.py#L64-L78#
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/users.py

    defaults: ->

      username: ''             # Max 255 chars. Must be unique among usernames.
                               # May contain only letters of the English
                               # alphabet, numbers and the underscore. Required
                               # during user creation. Only administrators can
                               # update usernames.
      password: ''             # Max 255 chars. Required during user creation.
                               # - must contain at least 8 chars
                               # - must either
                               #   - contain at least one character that is not
                               #     in the printable ASCII range', or
                               #   - contain at least one symbol, one digit,
                               #     one uppercase letter and one lowercase
                               #     letter
                               # - must match `passwordConfirm` value.
                               #
      password_confirm: ''      # Max 255 chars.
      first_name: ''           # Max 255 chars, can't be empty.
      last_name: ''            # Max 255 chars, can't be empty.
      email: ''                # Valid email, max 255 chars, can't be empty.
      affiliation: ''          # Max 255 chars.
      role: ''                 # One of "viewer", "contributor", or
                               # "administrator", can't be empty. Can only be
                               # changed by an administrator.
      markup_language: ''      # One of "Markdown" or "reStructuredText",
                               # defaults to "reStructuredText".
      page_content: ''         # A string of lightweight markup.
      input_orthography: null  # An OLD orthography object.
      output_orthography: null # An OLD orthography object.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null                 # The relational id given to the user model.
      datetime_modified: ''    # When the user was last modified.
      html: ''                 # HTML generated from the user-supplied markup.

    editableAttributes: [
      'first_name'
      'last_name'
      'email'
      'affiliation'
      'markup_language'
      'page_content'
      'input_orthography'
      'output_orthography'
      'role'               # ONLY EDITABLE BY ADMINS
      'username'           # ONLY EDITABLE BY ADMINS
      'password'           # ONLY EDITABLE BY ADMINS
      'password_confirm'   # ONLY EDITABLE BY ADMINS
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'first_name' then @requiredString
        when 'last_name' then @requiredString
        when 'email' then @validEmail
        when 'username' then @validUsername
        when 'password' then @validPassword
        when 'password_confirm' then @validPasswordConfirm
        else null

    validUsername: (value) ->
      if @get('id')
        if value
          if @containsOnlyWordCharacters value
            null
          else
            'The username may contain only letters of the English alphabet,
              numbers and the underscore.'
        else
          null
      else
        emptyError = @requiredString value
        if emptyError
          emptyError
        else
          if @containsOnlyWordCharacters value
            null
          else
            'The username may contain only letters of the English alphabet,
              numbers and the underscore.'

    containsOnlyWordCharacters: (string) ->
      /[^\w]/.test(string) is false

    validPassword: (value) ->
      @_validPassword value

    validPasswordConfirm: (value) ->
      @_validPassword value, false

    _validPassword: (value, validatingPassword=true) ->
      if value
        if validatingPassword
          counterpart = 'password_confirm'
        else
          counterpart = 'password'
        if value is @get(counterpart)
          if value.length < 8
            'Passwords must contain at least 8 characters.'
          else if not @passwordIsSecure(value)
            'Passwords must either contain at least one character that is not
              in the printable ASCII range or else they must contain at least
              one symbol, one digit, one uppercase letter, and one lowercase
              letter.'
          else
            null
        else
          'The “password” and “password confirm” values do not match.'
      else
        if @get 'id'
          null
        else
          'A password must be provided when creating a new user.'

    passwordIsSecure: (password) ->
      if @containsNonASCIIChars password
        true
      else if @isHighEntropyASCII password
        true
      else
        false

    containsNonASCIIChars: (password) ->
      (c for c in password when c.charCodeAt(0) not in [32...127]).length > 0

    # Returns `true` if the password has a lowercase character, an uppercase
    # character, a digit and a symbol.
    isHighEntropyASCII: (password) ->
      /[a-z]/.test(password) and
      /[A-Z]/.test(password) and
      /[0-9]/.test(password) and
      /[-!$%^&*()_+|~=`{}\[\]:";'<>?,./]/.test(password)

    validEmail: (value) ->
      emptyError = @requiredString value
      if emptyError
        emptyError
      else
        emailIsValid = @utils.emailIsValid value
        if emailIsValid
          null
        else
          'This does not appear to be a valid email address.'

    manyToOneAttributes: [
      'input_orthography'
      'output_orthography'
    ]

