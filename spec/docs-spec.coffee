path = require 'path'
express = require 'express'
http = require 'http'
vpm = require '../lib/vpm-cli'
Docs = require('../lib/docs')

describe 'vpm docs', ->
  server = null

  beforeEach ->
    silenceOutput()
    spyOnToken()

    app = express()
    app.get '/wrap-guide', (request, response) ->
      response.sendfile path.join(__dirname, 'fixtures', 'wrap-guide.json')
    app.get '/install', (request, response) ->
      response.sendfile path.join(__dirname, 'fixtures', 'install.json')
    server =  http.createServer(app)
    server.listen(3000)

    process.env.VIA_PACKAGES_URL = "http://localhost:3000"

  afterEach ->
    server.close()

  it 'logs an error if the package has no URL', ->
    callback = jasmine.createSpy('callback')
    vpm.run(['docs', 'install'], callback)

    waitsFor 'waiting for command to complete', ->
      callback.callCount > 0
    runs ->
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0

  it "logs an error if the package name is missing or empty", ->
    callback = jasmine.createSpy('callback')
    vpm.run(['docs'], callback)

    waitsFor 'waiting for command to complete', ->
      callback.callCount > 0

    runs ->
      expect(console.error).toHaveBeenCalled()
      expect(console.error.argsForCall[0][0].length).toBeGreaterThan 0

  it "prints the package URL if called with the --print option (and does not open it)", ->
    spyOn(Docs.prototype, 'openRepositoryUrl')
    callback = jasmine.createSpy('callback')
    vpm.run(['docs', '--print', 'wrap-guide'], callback)

    waitsFor 'waiting for command to complete', ->
      callback.callCount > 0

    runs ->
      expect(Docs::openRepositoryUrl).not.toHaveBeenCalled()
      expect(console.log).toHaveBeenCalled()
      expect(console.log.argsForCall[0][0]).toContain 'https://github.com/via/wrap-guide'

  it "prints the package URL if called with the -p short option (and does not open it)", ->
    Docs = require('../lib/docs')
    spyOn(Docs.prototype, 'openRepositoryUrl')
    callback = jasmine.createSpy('callback')
    vpm.run(['docs', '-p', 'wrap-guide'], callback)

    waitsFor 'waiting for command to complete', ->
      callback.callCount > 0

    runs ->
      expect(Docs::openRepositoryUrl).not.toHaveBeenCalled()
      expect(console.log).toHaveBeenCalled()
      expect(console.log.argsForCall[0][0]).toContain 'https://github.com/via/wrap-guide'

  it "opens the package URL", ->
    spyOn(Docs.prototype, 'openRepositoryUrl')
    callback = jasmine.createSpy('callback')
    vpm.run(['docs', 'wrap-guide'], callback)

    waitsFor 'waiting for command to complete', ->
      callback.callCount > 0

    runs ->
      expect(Docs::openRepositoryUrl).toHaveBeenCalled()
