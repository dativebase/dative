# Utility functions and classes

define (require) ->

  # Clone an Object (deep copy)
  # From http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning
  clone = (obj) ->
    if not obj? or typeof obj isnt 'object'
      return obj

    if obj instanceof Date
      return new Date(obj.getTime())

    if obj instanceof RegExp
      flags = ''
      flags += 'g' if obj.global?
      flags += 'i' if obj.ignoreCase?
      flags += 'm' if obj.multiline?
      flags += 'y' if obj.sticky?
      return new RegExp(obj.source, flags)

    newInstance = new obj.constructor()

    for key of obj
      newInstance[key] = clone obj[key]

    return newInstance

  # Type function which is superior to typeof.
  # See http://coffeescriptcookbook.com/chapters/classes_and_objects/type-function
  type = (obj) ->
    if obj == undefined or obj == null
      return String obj
    classToType = {
      '[object Boolean]': 'boolean',
      '[object Number]': 'number',
      '[object String]': 'string',
      '[object Function]': 'function',
      '[object Array]': 'array',
      '[object Date]': 'date',
      '[object RegExp]': 'regexp',
      '[object Object]': 'object'
    }
    return classToType[Object.prototype.toString.call(obj)]

  s4 = ->
    (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

  guid = ->
    "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}"

  # Email validator. This is the second regex of the second answer to
  # http://stackoverflow.com/questions/46155/validate-email-address-in-javascript
  emailIsValid = (email) ->
    regex = /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
    return regex.test(email)

  startsWith = (s, prefix) -> s[...prefix.length] is prefix

  endsWith = (s, suffix) -> suffix is '' or s[-suffix.length..] is suffix

  integerWithCommas = (integer) ->
    integer.toString().replace /\B(?=(\d{3})+(?!\d))/g, ','

  singularize = (noun) ->
    try
      if endsWith(noun, 'ies')
        "#{noun[0..-4]}y"
      else
        noun[...-1]
    catch
      noun

  pluralize = (noun) ->
    if endsWith noun, 'y'
      "#{noun[...-1]}ies"
    else if endsWith noun, 'us' # "corpus/corpora"
      "#{noun[...-2]}ora"
    else if endsWith(noun, 'z') or
    endsWith(noun, 's') or
    endsWith(noun, 'sh') or
    endsWith(noun, 'ch')
      "#{noun}es"
    else
      "#{noun}s"

  pluralizeByNum = (noun, numeral) ->
    switch numeral
      when 1 then noun
      else pluralize noun

  # Parses a date(time) string to a Date instance
  dateString2object = (dateString) ->
    try # Some FieldDB dates are enclosed in double quotation marks
      dateString = dateString.replace /"/g, ''
    date = new Date(Date.parse(dateString))
    if date.toString() is 'Invalid Date' then dateString else date

  # Return `unknown` as a JavaScript `Date` instance, if possible.
  asDateObject = (unknown) ->
    if type(unknown) is 'date'
      unknown
    else if type(unknown) is 'string'
      try
        dateString2object unknown
      catch
        unknown
    else
      null

  # Returns a `Date` instance as "January 1, 2015 at 5:45 p.m.", etc.
  humanDatetime = (dateObject) ->
    dateObject = asDateObject dateObject
    if type(dateObject) in ['string', 'null'] then return dateObject
    humanDateString = humanDate dateObject
    if not humanDateString then return null
    "#{humanDateString} at #{humanTime dateObject}"

  # Returns a `Date` instance as "January 1, 2015", etc.
  humanDate = (dateObject) ->
    dateObject = asDateObject dateObject
    if type(dateObject) in ['string', 'null'] then return dateObject
    try
      monthNames = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]
      ["#{monthNames[dateObject.getMonth()]}",
      "#{dateObject.getDate()},",
      "#{dateObject.getFullYear()}"].join ' '
    catch
      null

  # Returns the time portion of a `Date` instance as "5:45 p.m.", etc.
  humanTime = (dateObject) ->
    try
      hours = dateObject.getHours()
      minutes = dateObject.getMinutes()
      ampm = if hours >= 12 then 'p.m.' else 'a.m.'
      hours = hours % 12
      hours = if hours then hours else 12 # the hour '0' should be '12'
      minutes = if minutes < 10 then "0#{minutes}" else minutes
      "#{hours}:#{minutes} #{ampm}"
    catch
      return null

  # Takes a Date instance and returns a string indicating how long ago it was from now.
  timeSince = (dateObject) ->
    dateObject = asDateObject dateObject
    if type(dateObject) in ['string', 'null'] then return dateObject
    try
      date = dateObject.getTime()
    catch
      return null
    if isNaN date then return ''
    seconds = Math.floor((new Date() - date) / 1000)
    interval = Math.floor(seconds / 31536000)
    if interval > 1 then return "#{interval} years ago"
    interval = Math.floor(seconds / 2592000)
    if interval > 1 then return "#{interval} months ago"
    interval = Math.floor(seconds / 86400)
    if interval > 1 then return "#{interval} days ago"
    interval = Math.floor(seconds / 3600)
    if interval > 1 then return "#{interval} hours ago"
    interval = Math.floor(seconds / 60)
    if interval > 1 then return "#{interval} minutes ago"
    return "#{Math.floor(seconds)} seconds ago"

  # "snake_case" to "camelCase"
  snake2camel = (string) ->
    string.replace(/(_[a-z])/g, ($1) ->
      $1.toUpperCase().replace('_',''))

  # "snake_case" to "hyphen-case"
  snake2hyphen = (string) ->
    string.replace /_/g, '-'

  # "snake_case" to "regular case"
  snake2regular = (string) ->
    string.replace /_/g, ' '

  # "camelCase" to "snake_case"
  camel2snake = (string) ->
    string.replace(/([A-Z])/g, ($1) ->
      "_#{$1.toLowerCase()}")

  # "camelCase" to "camel case".
  camel2regular = (string) ->
    string
      .replace /([A-Z])/g, ' $1'
      .toLowerCase()
      .trim()

  # "camelCase" to "camel Case". Insert a space before all caps and uppercase
  # the first character
  camel2regularUpper = (string) ->
    string
      .replace /([A-Z])/g, ' $1'
      .replace /^./, (str) -> str.toUpperCase()
      .trim()

  # "camelCase" to "camel-case". Insert a hyphen before all caps and lowercase everything.
  camel2hyphen = (string) ->
    string
      .replace /([A-Z])/g, '-$1'
      .toLowerCase()
      .trim()

  capitalize = (string) ->
    try
      "#{string[0].toUpperCase()}#{string[1..-1]}"
    catch
      string

  # Enclose `enclosee` in `start` and `end` characters, only if they're not
  # already there.
  encloseIfNotAlready = (enclosee, start, end) ->
    if not enclosee? then return enclosee
    [first, ..., last] = enclosee
    start = if first is start then '' else start
    end   = if last  is end   then '' else end
    "#{start}#{enclosee}#{end}"

  log = (thingToLog) ->
    console.log JSON.stringify(thingToLog, undefined, 2)

  getTimestamp = -> new Date().getTime()

  # Returns `string` with all of its acronyms enclosed in `<span
  # class="small-caps">`. NOTE: assumes that an acronyms is any sequence of two
  # or more uppercase ASCII characters.
  smallCapsAcronyms = (string) ->
    string.replace(/([A-Z]{2,})/g, (match, $1) ->
      "<span class='small-caps'>#{$1.toLowerCase()}</span>")

  isoDateRegex = /^\d{4}-\d{2}-\d{2}$/

  # Convert a date like "2015-03-16" to "03/16/2015". Note that the OLD
  # accepts dates in the latter format (because of how Pylons' FormEncode
  # validation works), but returns them in the former (ISO 8601) format.
  convertDateISO2mdySlash = (date) ->
    if isoDateRegex.test date
      [year, month, day] = date.split '-'
      "#{month}/#{day}/#{year}"
    else
      date

  # See http://stackoverflow.com/questions/985272/selecting-text-in-an-element-akin-to-highlighting-with-your-mouse
  selectText = (element) ->
    if document.body.createTextRange
      range = document.body.createTextRange()
      range.moveToElementText element
      range.select()
    else if window.getSelection
      selection = window.getSelection()
      range = document.createRange()
      range.selectNodeContents element
      selection.removeAllRanges()
      selection.addRange range

  clone: clone
  type: type
  guid: guid
  emailIsValid: emailIsValid
  startsWith: startsWith
  endsWith: endsWith
  integerWithCommas: integerWithCommas
  singularize: singularize
  pluralize: pluralize
  pluralizeByNum: pluralizeByNum
  timeSince: timeSince
  humanDatetime: humanDatetime
  humanDate: humanDate
  humanTime: humanTime
  dateString2object: dateString2object
  snake2camel: snake2camel
  snake2hyphen: snake2hyphen
  snake2regular: snake2regular
  camel2snake: camel2snake
  camel2regular: camel2regular
  camel2hyphen: camel2hyphen
  capitalize: capitalize
  encloseIfNotAlready: encloseIfNotAlready
  log: log
  getTimestamp: getTimestamp
  smallCapsAcronyms: smallCapsAcronyms
  convertDateISO2mdySlash: convertDateISO2mdySlash
  selectText: selectText

