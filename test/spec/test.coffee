hello = ->
  'Hello World'

describe 'Give it some context', ->
  describe 'maybe a bit more context here', ->
    it 'should be equal (in test/spec/test.coffee) using "expect"', ->
      expect(hello()).to.equal 'hello World'

