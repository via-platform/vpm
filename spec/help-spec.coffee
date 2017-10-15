vpm = require '../lib/vpm-cli'

describe 'command help', ->
  beforeEach ->
    spyOnToken()
    silenceOutput()

  describe "vpm help publish", ->
    it "displays the help for the command", ->
      callback = jasmine.createSpy('callback')
      vpm.run(['help', 'publish'], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()

  describe "vpm publish -h", ->
    it "displays the help for the command", ->
      callback = jasmine.createSpy('callback')
      vpm.run(['publish', '-h'], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()

  describe "vpm help", ->
    it "displays the help for vpm", ->
      callback = jasmine.createSpy('callback')
      vpm.run(['help'], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()

  describe "vpm", ->
    it "displays the help for vpm", ->
      callback = jasmine.createSpy('callback')
      vpm.run([], callback)

      waitsFor 'waiting for help to complete', 60000, ->
        callback.callCount is 1

      runs ->
        expect(console.error.callCount).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).toBeUndefined()
