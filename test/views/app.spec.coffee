
# - Views can render the target HTML, binding model data to a templatesate string
# - View objects provided with an el property get added to thehe DOM on creation
# - View methods correctly bind to DOM and Backbone.Viewsjs events, and respond appropriately
# - Objects contained by a view (formor example, subviews and models) are properly disposed on the view removal

define (require) ->

  AppView = require '../../../scripts/views/app'

  describe 'App View', ->

    it 'does stuff', ->
      expect(true).to.be.ok

