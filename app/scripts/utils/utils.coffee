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

  clone: clone
  type: type
  guid: guid
  emailIsValid: emailIsValid

