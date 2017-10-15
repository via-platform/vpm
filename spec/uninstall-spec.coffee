path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
vpm = require '../lib/vpm-cli'

describe 'vpm uninstall', ->
  beforeEach ->
    silenceOutput()
    spyOnToken()
    process.env.VIA_API_URL = 'http://localhost:5432'

  describe 'when no package is specified', ->
    it 'logs an error and exits', ->
      callback = jasmine.createSpy('callback')
      vpm.run(['uninstall'], callback)

      waitsFor 'waiting for command to complete', ->
        callback.callCount > 0

      runs ->
        expect(console.error.mostRecentCall.args[0].length).toBeGreaterThan 0
        expect(callback.mostRecentCall.args[0]).not.toBeUndefined()

  describe 'when the package is not installed', ->
    it 'ignores the package', ->
      callback = jasmine.createSpy('callback')
      vpm.run(['uninstall', 'a-package-that-does-not-exist'], callback)

      waitsFor 'waiting for command to complete', ->
        callback.callCount > 0

      runs ->
        expect(console.error.callCount).toBe 1

  describe 'when the package is installed', ->
    it 'deletes the package', ->
      viaHome = temp.mkdirSync('vpm-home-dir-')
      packagePath = path.join(viaHome, 'packages', 'test-package')
      fs.makeTreeSync(path.join(packagePath, 'lib'))
      fs.writeFileSync(path.join(packagePath, 'package.json'), "{}")
      process.env.VIA_HOME = viaHome

      expect(fs.existsSync(packagePath)).toBeTruthy()
      callback = jasmine.createSpy('callback')
      vpm.run(['uninstall', 'test-package'], callback)

      waitsFor 'waiting for command to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(packagePath)).toBeFalsy()

    describe "--dev", ->
      it "deletes the packages from the dev packages folder", ->
        viaHome = temp.mkdirSync('vpm-home-dir-')
        packagePath = path.join(viaHome, 'packages', 'test-package')
        fs.makeTreeSync(path.join(packagePath, 'lib'))
        fs.writeFileSync(path.join(packagePath, 'package.json'), "{}")
        devPackagePath = path.join(viaHome, 'dev', 'packages', 'test-package')
        fs.makeTreeSync(path.join(devPackagePath, 'lib'))
        fs.writeFileSync(path.join(devPackagePath, 'package.json'), "{}")
        process.env.VIA_HOME = viaHome

        expect(fs.existsSync(packagePath)).toBeTruthy()
        callback = jasmine.createSpy('callback')
        vpm.run(['uninstall', 'test-package', '--dev'], callback)

        waitsFor 'waiting for command to complete', ->
          callback.callCount > 0

        runs ->
          expect(fs.existsSync(devPackagePath)).toBeFalsy()
          expect(fs.existsSync(packagePath)).toBeTruthy()

    describe "--hard", ->
      it "deletes the packages from the both packages folders", ->
        viaHome = temp.mkdirSync('vpm-home-dir-')
        packagePath = path.join(viaHome, 'packages', 'test-package')
        fs.makeTreeSync(path.join(packagePath, 'lib'))
        fs.writeFileSync(path.join(packagePath, 'package.json'), "{}")
        devPackagePath = path.join(viaHome, 'dev', 'packages', 'test-package')
        fs.makeTreeSync(path.join(devPackagePath, 'lib'))
        fs.writeFileSync(path.join(devPackagePath, 'package.json'), "{}")
        process.env.VIA_HOME = viaHome

        expect(fs.existsSync(packagePath)).toBeTruthy()
        callback = jasmine.createSpy('callback')
        vpm.run(['uninstall', 'test-package', '--hard'], callback)

        waitsFor 'waiting for command to complete', ->
          callback.callCount > 0

        runs ->
          expect(fs.existsSync(devPackagePath)).toBeFalsy()
          expect(fs.existsSync(packagePath)).toBeFalsy()
