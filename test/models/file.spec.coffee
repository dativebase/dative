# global beforeEach, describe, it, assert, expect
"use strict"

describe 'File Model', ->
  beforeEach ->
    @FileModel = new Dative.Models.File();
