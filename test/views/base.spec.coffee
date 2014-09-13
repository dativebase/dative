define (require) ->

  BaseView = require '../../../scripts/views/base'

  describe 'Base View', ->

    before ->
      # Spy on some of BaseView's methods

    beforeEach (done) ->

      # Create test fixture using js-fixtures https://github.com/badunk/js-fixtures
      fixtures.path = 'fixtures'
      callback = =>
        @$fixture = fixtures.window().$("<div id='js-fixtures-fixture'></div>")
        @$ = (selector) -> @$fixture.find selector
        @baseView = new BaseView el: @$fixture # New baseView for each test
        done()
      fixtures.load('fixture.html', callback)

    afterEach ->

      fixtures.cleanUp()
      @baseView.close()
      @baseView.remove()
      # Reset spies/stubs

    after ->
      # Restore spies

    describe 'String manipulation', ->

      it 'trims strings', ->
        expect(@baseView.trim('\n\t    fargo\t   ')).to.equal 'fargo'
        expect(@baseView.trim('    and   then\t\n\n   ')).to.equal 'and   then'

      it 'converts snake case to camel case and back again', ->
        expect(@baseView.snake2camel('big_important_var'))
          .to.equal 'bigImportantVar'
        expect(@baseView.camel2snake('bigImportantVar'))
          .to.equal 'big_important_var'

    describe 'Subview management', ->

      it 'closes rendered subviews on self.close', ->

        @baseView.$el.html '<div id="subviewOne"></div><div id="subviewTwo"></div>'

        sinon.spy @baseView, 'close'

        # subview one
        @baseView.subviewOne = new BaseView()
        @baseView.subviewOne.setElement @baseView.$('#subviewOne')
        @baseView.subviewOne.$el.html '<button class="clickme">Click Me!</button>'
        @baseView.rendered @baseView.subviewOne
        @baseView.subviewOne.clickResponder = sinon.spy()
        @baseView.subviewOne.delegateEvents 'click .clickme': 'clickResponder'
        sinon.spy @baseView.subviewOne, 'close'

        # subview two
        @baseView.subviewTwo = new BaseView()
        @baseView.subviewTwo.setElement @baseView.$('#subviewTwo')
        @baseView.subviewTwo.$el.html '<span>I am subview 2</span>'
        @baseView.rendered @baseView.subviewTwo
        sinon.spy @baseView.subviewTwo, 'close'

        # subview one responds to Backbone events
        @baseView.subviewOne.eventResponder = sinon.spy()
        @baseView.subviewOne.listenTo Backbone, 'all', @baseView.subviewOne.eventResponder
        expect(@baseView.subviewOne.eventResponder).not.to.have.been.called
        Backbone.trigger 'nonsense'
        expect(@baseView.subviewOne.eventResponder).to.have.been.calledOnce

        # subview one responds to its button being clicked
        expect(@baseView.subviewOne.clickResponder).not.to.have.been.called
        @baseView.subviewOne.$('.clickme').click()
        expect(@baseView.subviewOne.clickResponder).to.have.been.calledOnce

        # Close the base view
        expect(@baseView.close).not.to.have.been.called
        expect(@baseView.subviewOne.close).not.to.have.been.called
        expect(@baseView.subviewTwo.close).not.to.have.been.called
        @baseView.close()
        expect(@baseView.close).to.have.been.calledOnce
        expect(@baseView.subviewOne.close).to.have.been.calledOnce
        expect(@baseView.subviewTwo.close).to.have.been.calledOnce

        # subview one no longer responds to Backbone-wide events (because
        # stopListening is called in BaseView.close)
        Backbone.trigger 'nonsense'
        expect(@baseView.subviewOne.eventResponder).to.have.been.calledOnce

        # subview one no longer responds to its button being clicked (because
        # undelegateEvents has been called in BaseView.close)
        @baseView.subviewOne.$('.clickme').click()
        expect(@baseView.subviewOne.clickResponder).to.have.been.calledOnce

        @baseView.close.restore()
        @baseView.subviewOne.close.restore()
        @baseView.subviewTwo.close.restore()

      it 'recursively closes subviews', ->

        @baseView.$el.html '<div id="subviewOne"></div>'

        sinon.spy @baseView, 'close'

        # subview 1
        subviewOne = @baseView.subviewOne = new BaseView()
        subviewOne.setElement @baseView.$('#subviewOne')
        subviewOne.$el.html '<div id="subviewOneA"></div>'
        @baseView.rendered subviewOne
        sinon.spy subviewOne, 'close'

        # subview 1a (subview of subview 1)
        subviewOneA = subviewOne.subviewOneA = new BaseView()
        subviewOneA.setElement subviewOne.$('#subviewOneA')
        subviewOneA.$el.html '<button class="clickme">Click Me!</button>'
        subviewOne.rendered subviewOneA
        sinon.spy subviewOneA, 'close'
        subviewOneA.clickResponder = sinon.spy()
        subviewOneA.delegateEvents 'click .clickme': 'clickResponder'

        # subview 1a responds to Backbone events
        subviewOneA.eventResponder = sinon.spy()
        subviewOneA.listenTo Backbone, 'all', subviewOneA.eventResponder
        expect(subviewOneA.eventResponder).not.to.have.been.called
        Backbone.trigger 'nonsense'
        expect(subviewOneA.eventResponder).to.have.been.calledOnce

        # subview 1a responds to its button being clicked
        expect(subviewOneA.clickResponder).not.to.have.been.called
        subviewOneA.$('.clickme').click()
        expect(subviewOneA.clickResponder).to.have.been.calledOnce

        # Close subview 1
        expect(@baseView.close).not.to.have.been.called
        expect(subviewOne.close).not.to.have.been.called
        expect(subviewOneA.close).not.to.have.been.called
        expect(@baseView._renderedSubViews).to.contain(subviewOne).and
          .to.have.length 1
        expect(subviewOne._renderedSubViews).to.contain(subviewOneA).and
          .to.have.length 1
        expect(subviewOneA._renderedSubViews).to.be.undefined
        subviewOne.close()
        @baseView.closed subviewOne
        expect(@baseView.close).not.to.have.been.called
        expect(subviewOne.close).to.have.been.calledOnce
        expect(subviewOneA.close).to.have.been.calledOnce
        expect(@baseView._renderedSubViews).to.have.length 0
        expect(subviewOne._renderedSubViews).to.contain(subviewOneA).and
          .to.have.length 1 # Note: `.closed` is not called recursively by `.close`
        expect(subviewOneA._renderedSubViews).to.be.undefined

        # subview 1a no longer responds to Backbone-wide events (because
        # stopListening is called in BaseView.close)
        Backbone.trigger 'nonsense'
        expect(subviewOneA.eventResponder).to.have.been.calledOnce

        # subview 1a no longer responds to its button being clicked (because
        # undelegateEvents has been called in BaseView.close)
        subviewOneA.$('.clickme').click()
        expect(subviewOneA.clickResponder).to.have.been.calledOnce

        @baseView.close.restore()
        subviewOne.close.restore()
        subviewOneA.close.restore()

