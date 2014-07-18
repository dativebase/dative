# global beforeEach, describe, it, assert, expect
"use strict"

describe 'App View', ->
  #beforeEach ->
  # @AppView = new AppView()
  it "should be equal using 'expect'", ->
    expect(hello()).to.equal "Hello World"

