child_process = require 'child_process'
fs = require 'fs'
path = require 'path'
temp = require 'temp'
vpm = require '../lib/vpm-cli'

describe "vpm test", ->
  [specPath] = []

  beforeEach ->
    silenceOutput()
    spyOnToken()

    currentDir = temp.mkdirSync('vpm-init-')
    spyOn(process, 'cwd').andReturn(currentDir)
    specPath = path.join(currentDir, 'spec')

  it "calls via to test", ->
    viaSpawn = spyOn(child_process, 'spawn').andReturn
      stdout:
        on: ->
      stderr:
        on: ->
      on: ->
    vpm.run(['test'])

    waitsFor 'waiting for test to complete', ->
      viaSpawn.callCount is 1

    runs ->
      if process.platform is 'win32'
        expect(viaSpawn.mostRecentCall.args[1][2].indexOf('via')).not.toBe -1
        expect(viaSpawn.mostRecentCall.args[1][2].indexOf('--dev')).not.toBe -1
        expect(viaSpawn.mostRecentCall.args[1][2].indexOf('--test')).not.toBe -1
      else
        expect(viaSpawn.mostRecentCall.args[0]).toEqual 'via'
        expect(viaSpawn.mostRecentCall.args[1][0]).toEqual '--dev'
        expect(viaSpawn.mostRecentCall.args[1][1]).toEqual '--test'
        expect(viaSpawn.mostRecentCall.args[1][2]).toEqual specPath
        expect(viaSpawn.mostRecentCall.args[2].streaming).toBeTruthy()

  describe 'returning', ->
    [callback] = []

    returnWithCode = (type, code) ->
      callback = jasmine.createSpy('callback')
      viaReturnFn = (e, fn) -> fn(code) if e is type
      spyOn(child_process, 'spawn').andReturn
        stdout:
          on: ->
        stderr:
          on: ->
        on: viaReturnFn
        removeListener: -> # no op
      vpm.run(['test'], callback)

    describe 'successfully', ->
      beforeEach -> returnWithCode('close', 0)

      it "prints success", ->
        expect(callback).toHaveBeenCalled()
        expect(callback.mostRecentCall.args[0]).toBeUndefined()
        expect(process.stdout.write.mostRecentCall.args[0]).toEqual 'Tests passed\n'.green

    describe 'with a failure', ->
      beforeEach -> returnWithCode('close', 1)

      it "prints failure", ->
        expect(callback).toHaveBeenCalled()
        expect(callback.mostRecentCall.args[0]).toEqual 'Tests failed'

    describe 'with an error', ->
      beforeEach -> returnWithCode('error')

      it "prints failure", ->
        expect(callback).toHaveBeenCalled()
        expect(callback.mostRecentCall.args[0]).toEqual 'Tests failed'
