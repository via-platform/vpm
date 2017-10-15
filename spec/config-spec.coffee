path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
vpm = require '../lib/vpm-cli'

describe "vpm config", ->
  [viaHome, userConfigPath] = []

  beforeEach ->
    spyOnToken()
    silenceOutput()

    viaHome = temp.mkdirSync('vpm-home-dir-')
    process.env.VIA_HOME = viaHome
    userConfigPath = path.join(viaHome, '.vpmrc')

    # Make sure the cache used is the one for the test env
    delete process.env.npm_config_cache

  describe "vpm config get", ->
    it "reads the value from the global config when there is no user config", ->
      callback = jasmine.createSpy('callback')
      vpm.run(['config', 'get', 'cache'], callback)

      waitsFor 'waiting for config get to complete', 600000, ->
        callback.callCount is 1

      runs ->
        expect(process.stdout.write.argsForCall[0][0].trim()).toBe path.join(process.env.VIA_HOME, '.vpm')

  describe "vpm config set", ->
    it "sets the value in the user config", ->
      expect(fs.isFileSync(userConfigPath)).toBe false

      callback = jasmine.createSpy('callback')
      vpm.run(['config', 'set', 'foo', 'bar'], callback)

      waitsFor 'waiting for config set to complete', 600000, ->
        callback.callCount is 1

      runs ->
        expect(fs.isFileSync(userConfigPath)).toBe true

        callback.reset()
        vpm.run(['config', 'get', 'foo'], callback)

      waitsFor 'waiting for config get to complete', 600000, ->
        callback.callCount is 1

      runs ->
        expect(process.stdout.write.argsForCall[0][0].trim()).toBe 'bar'
