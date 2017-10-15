path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
vpm = require '../lib/vpm-cli'

describe "vpm develop", ->
  [repoPath, linkedRepoPath] = []

  beforeEach ->
    silenceOutput()
    spyOnToken()

    viaHome = temp.mkdirSync('vpm-home-dir-')
    process.env.VIA_HOME = viaHome

    viaReposHome = temp.mkdirSync('vpm-repos-home-dir-')
    process.env.VIA_REPOS_HOME = viaReposHome

    repoPath = path.join(viaReposHome, 'fake-package')
    linkedRepoPath = path.join(viaHome, 'dev', 'packages', 'fake-package')

  describe "when the package doesn't have a published repository url", ->
    it "logs an error", ->
      Develop = require '../lib/develop'
      spyOn(Develop.prototype, "getRepositoryUrl").andCallFake (packageName, callback) ->
        callback("Here is the error")

      callback = jasmine.createSpy('callback')
      vpm.run(['develop', "fake-package"], callback)

      waitsFor 'waiting for develop to complete', ->
        callback.callCount is 1

      runs ->
        expect(callback.mostRecentCall.args[0]).toBe "Here is the error"
        expect(fs.existsSync(repoPath)).toBeFalsy()
        expect(fs.existsSync(linkedRepoPath)).toBeFalsy()

  describe "when the repository hasn't been cloned", ->
    it "clones the repository to VIA_REPOS_HOME and links it to VIA_HOME/dev/packages", ->
      Develop = require '../lib/develop'
      spyOn(Develop.prototype, "getRepositoryUrl").andCallFake (packageName, callback) ->
        repoUrl = path.join(__dirname, 'fixtures', 'repo.git')
        callback(null, repoUrl)
      spyOn(Develop.prototype, "installDependencies").andCallFake (packageDirectory, options) ->
        @linkPackage(packageDirectory, options)

      callback = jasmine.createSpy('callback')
      vpm.run(['develop', "fake-package"], callback)

      waitsFor 'waiting for develop to complete', ->
        callback.callCount is 1

      runs ->
        expect(callback.mostRecentCall.args[0]).toBeFalsy()
        expect(fs.existsSync(repoPath)).toBeTruthy()
        expect(fs.existsSync(path.join(repoPath, 'Syntaxes', 'Makefile.plist'))).toBeTruthy()
        expect(fs.existsSync(linkedRepoPath)).toBeTruthy()
        expect(fs.realpathSync(linkedRepoPath)).toBe fs.realpathSync(repoPath)

  describe "when the repository has already been cloned", ->
    it "links it to VIA_HOME/dev/packages", ->
      fs.makeTreeSync(repoPath)
      fs.writeFileSync(path.join(repoPath, "package.json"), "")
      callback = jasmine.createSpy('callback')
      vpm.run(['develop', "fake-package"], callback)

      waitsFor 'waiting for develop to complete', ->
        callback.callCount is 1

      runs ->
        expect(callback.mostRecentCall.args[0]).toBeFalsy()
        expect(fs.existsSync(repoPath)).toBeTruthy()
        expect(fs.existsSync(linkedRepoPath)).toBeTruthy()
        expect(fs.realpathSync(linkedRepoPath)).toBe fs.realpathSync(repoPath)
