# global beforeEach, describe, it, assert, expect
"use strict"

describe 'Pages Collection', ->
  beforeEach ->
    @PagesCollection = new Dative.Collections.Pages()
