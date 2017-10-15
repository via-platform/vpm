fs = require 'fs'
path = require 'path'
temp = require 'temp'
vpm = require '../lib/vpm-cli'

describe 'vpm link/unlink', ->
  beforeEach ->
    silenceOutput()
    spyOnToken()

  describe "when the dev flag is false (the default)", ->
    it 'symlinks packages to $VIA_HOME/packages', ->
      viaHome = temp.mkdirSync('vpm-home-dir-')
      process.env.VIA_HOME = viaHome
      packageToLink = temp.mkdirSync('a-package-')
      process.chdir(packageToLink)
      callback = jasmine.createSpy('callback')

      runs ->
        vpm.run(['link'], callback)

      waitsFor 'waiting for link to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink)))).toBeTruthy()
        expect(fs.realpathSync(path.join(viaHome, 'packages', path.basename(packageToLink)))).toBe fs.realpathSync(packageToLink)

        callback.reset()
        vpm.run(['unlink'], callback)

      waitsFor 'waiting for unlink to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink)))).toBeFalsy()

  describe "when the dev flag is true", ->
    it 'symlinks packages to $VIA_HOME/dev/packages', ->
      viaHome = temp.mkdirSync('vpm-home-dir-')
      process.env.VIA_HOME = viaHome
      packageToLink = temp.mkdirSync('a-package-')
      process.chdir(packageToLink)
      callback = jasmine.createSpy('callback')

      runs ->
        vpm.run(['link', '--dev'], callback)

      waitsFor 'waiting for link to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'dev', 'packages', path.basename(packageToLink)))).toBeTruthy()
        expect(fs.realpathSync(path.join(viaHome, 'dev', 'packages', path.basename(packageToLink)))).toBe fs.realpathSync(packageToLink)

        callback.reset()
        vpm.run(['unlink', '--dev'], callback)

      waitsFor 'waiting for unlink to complete', ->
        callback.callCount > 0

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'dev', 'packages', path.basename(packageToLink)))).toBeFalsy()

  describe "when the hard flag is true", ->
    it "unlinks the package from both $VIA_HOME/packages and $VIA_HOME/dev/packages", ->
      viaHome = temp.mkdirSync('vpm-home-dir-')
      process.env.VIA_HOME = viaHome
      packageToLink = temp.mkdirSync('a-package-')
      process.chdir(packageToLink)
      callback = jasmine.createSpy('callback')

      runs ->
        vpm.run(['link', '--dev'], callback)

      waitsFor 'link --dev to complete', ->
        callback.callCount is 1

      runs ->
        vpm.run(['link'], callback)

      waitsFor 'link to complete', ->
        callback.callCount is 2

      runs ->
        vpm.run(['unlink', '--hard'], callback)

      waitsFor 'unlink --hard to complete', ->
        callback.callCount is 3

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'dev', 'packages', path.basename(packageToLink)))).toBeFalsy()
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink)))).toBeFalsy()

  describe "when the all flag is true", ->
    it "unlinks all packages in $VIA_HOME/packages and $VIA_HOME/dev/packages", ->
      viaHome = temp.mkdirSync('vpm-home-dir-')
      process.env.VIA_HOME = viaHome
      packageToLink1 = temp.mkdirSync('a-package-')
      packageToLink2 = temp.mkdirSync('a-package-')
      packageToLink3 = temp.mkdirSync('a-package-')
      callback = jasmine.createSpy('callback')

      runs ->
        vpm.run(['link', '--dev', packageToLink1], callback)

      waitsFor 'link --dev to complete', ->
        callback.callCount is 1

      runs ->
        callback.reset()
        vpm.run(['link', packageToLink2], callback)
        vpm.run(['link', packageToLink3], callback)

      waitsFor 'link to complee', ->
        callback.callCount is 2

      runs ->
        callback.reset()
        expect(fs.existsSync(path.join(viaHome, 'dev', 'packages', path.basename(packageToLink1)))).toBeTruthy()
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink2)))).toBeTruthy()
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink3)))).toBeTruthy()
        vpm.run(['unlink', '--all'], callback)

      waitsFor 'unlink --all to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'dev', 'packages', path.basename(packageToLink1)))).toBeFalsy()
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink2)))).toBeFalsy()
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(packageToLink3)))).toBeFalsy()

  describe "when the package name is numeric", ->
    it "still links and unlinks normally", ->
      viaHome = temp.mkdirSync('vpm-home-dir-')
      process.env.VIA_HOME = viaHome
      numericPackageName = temp.mkdirSync('42')
      callback = jasmine.createSpy('callback')

      runs ->
        vpm.run(['link', numericPackageName], callback)

      waitsFor 'link to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(numericPackageName)))).toBeTruthy()
        expect(fs.realpathSync(path.join(viaHome, 'packages', path.basename(numericPackageName)))).toBe fs.realpathSync(numericPackageName)

        callback.reset()
        vpm.run(['unlink', numericPackageName], callback)

      waitsFor 'unlink to complete', ->
        callback.callCount is 1

      runs ->
        expect(fs.existsSync(path.join(viaHome, 'packages', path.basename(numericPackageName)))).toBeFalsy()
