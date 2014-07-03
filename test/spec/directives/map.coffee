'use strict'

describe 'Directive: map', ->

  # load the directive's module
  beforeEach module 'parallelApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<map></map>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the map directive'
