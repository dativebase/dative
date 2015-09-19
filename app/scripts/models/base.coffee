define [
  'backbone'
  './../utils/cors'
  './../utils/utils'
], (Backbone, CORS, utils) ->

  # Base Model
  # ----------
  #
  # Functionality that all models and collections need.

  class BaseModel extends Backbone.Model

    guid: utils.guid
    @cors: new CORS()
    utils: utils

    requiredString: (value) ->
      if value?.trim?() in ['', undefined] then 'Please enter a value' else null

