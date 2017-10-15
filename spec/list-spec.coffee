path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
wrench = require 'wrench'
vpm = require '../lib/vpm-cli'
CSON = require 'season'

listPackages = (args, doneCallback) ->
  callback = jasmine.createSpy('callback')
  vpm.run ['list'].concat(args), callback

  waitsFor -> callback.callCount is 1

  runs(doneCallback)

createFakePackage = (type, metadata) ->
  packagesFolder = switch type
    when "user", "git" then "packages"
    when "dev" then path.join("dev", "packages")
  targetFolder = path.join(process.env.VIA_HOME, packagesFolder, metadata.name)
  fs.makeTreeSync targetFolder
  fs.writeFileSync path.join(targetFolder, 'package.json'), JSON.stringify(metadata)

removeFakePackage = (type, name) ->
  packagesFolder = switch type
    when "user", "git" then "packages"
    when "dev" then path.join("dev", "packages")
  targetFolder = path.join(process.env.VIA_HOME, packagesFolder, name)
  fs.removeSync(targetFolder)

describe 'vpm list', ->
  [resourcePath, viaHome] = []

  beforeEach ->
    silenceOutput()
    spyOnToken()

    resourcePath = temp.mkdirSync('vpm-resource-path-')
    viaPackages =
      'test-module':
        metadata:
          name: 'test-module'
          version: '1.0.0'
    fs.writeFileSync(path.join(resourcePath, 'package.json'), JSON.stringify(_viaPackages: viaPackages))
    process.env.VIA_RESOURCE_PATH = resourcePath
    viaHome = temp.mkdirSync('vpm-home-dir-')
    process.env.VIA_HOME = viaHome

    createFakePackage "user",
      name: "user-package"
      version: "1.0.0"
    createFakePackage "dev",
      name: "dev-package"
      version: "1.0.0"
    createFakePackage "git",
      name: "git-package"
      version: "1.0.0"
      vpmInstallSource:
        type: "git"
        source: "git+ssh://git@github.com:user/repo.git"
        sha: "abcdef1234567890"

    badPackagePath = path.join(process.env.VIA_HOME, "packages", ".bin")
    fs.makeTreeSync badPackagePath
    fs.writeFileSync path.join(badPackagePath, "file.txt"), "some fake stuff"

  it 'lists the installed packages', ->
    listPackages [], ->
      lines = console.log.argsForCall.map((arr) -> arr.join(' '))
      expect(lines[0]).toMatch /Built-in Atom Packages.*1/
      expect(lines[1]).toMatch /test-module@1\.0\.0/
      expect(lines[3]).toMatch /Dev Packages.*1/
      expect(lines[4]).toMatch /dev-package@1\.0\.0/
      expect(lines[6]).toMatch /Community Packages.*1/
      expect(lines[7]).toMatch /user-package@1\.0\.0/
      expect(lines[9]).toMatch /Git Packages.*1/
      expect(lines[10]).toMatch /git-package@1\.0\.0/
      expect(lines.join("\n")).not.toContain '.bin' # ensure invalid packages aren't listed

  it 'labels disabled packages', ->
    packagesPath = path.join(viaHome, 'packages')
    fs.makeTreeSync(packagesPath)
    wrench.copyDirSyncRecursive(path.join(__dirname, 'fixtures', 'test-module'), path.join(packagesPath, 'test-module'))
    configPath = path.join(viaHome, 'config.cson')
    CSON.writeFileSync configPath, '*':
      core: disabledPackages: ["test-module"]

    listPackages [], ->
      expect(console.log.argsForCall[1][0]).toContain 'test-module@1.0.0 (disabled)'

  it 'displays only enabled packages when --enabled is called', ->
    viaPackages =
      'test-module':
        metadata:
          name: 'test-module'
          version: '1.0.0'
      'test2-module':
        metadata:
          name: 'test2-module'
          version: '1.0.0'

    fs.writeFileSync(path.join(resourcePath, 'package.json'), JSON.stringify(_viaPackages: viaPackages))

    packagesPath = path.join(viaHome, 'packages')
    fs.makeTreeSync(packagesPath)
    wrench.copyDirSyncRecursive(path.join(__dirname, 'fixtures', 'test-module'), path.join(packagesPath, 'test-module'))
    configPath = path.join(viaHome, 'config.cson')
    CSON.writeFileSync configPath, '*':
      core: disabledPackages: ["test-module"]

    listPackages ['--enabled'], ->
      expect(console.log.argsForCall[1][0]).toContain 'test2-module@1.0.0'
      expect(console.log.argsForCall[4][0]).toContain 'dev-package@1.0.0'
      expect(console.log.argsForCall[7][0]).toContain 'user-package@1.0.0'
      expect(console.log.argsForCall[10][0]).toContain 'git-package@1.0.0'

  it 'lists packages in json format when --json is passed', ->
    listPackages ['--json'], ->
      json = JSON.parse(console.log.argsForCall[0][0])
      vpmInstallSource =
        type: 'git'
        source: 'git+ssh://git@github.com:user/repo.git'
        sha: 'abcdef1234567890'
      expect(json.core).toEqual [name: 'test-module', version: '1.0.0']
      expect(json.dev).toEqual [name: 'dev-package', version: '1.0.0']
      expect(json.git).toEqual [name: 'git-package', version: '1.0.0', vpmInstallSource: vpmInstallSource]
      expect(json.user).toEqual [name: 'user-package', version: '1.0.0']

  describe 'when a section is empty', ->
    it 'does not list anything for Dev and Git sections', ->
      removeFakePackage 'git', 'git-package'
      removeFakePackage 'dev', 'dev-package'
      listPackages [], ->
        output = console.log.argsForCall.map((arr) -> arr.join(' ')).join('\n')
        expect(output).not.toMatch /Git Packages/
        expect(output).not.toMatch /git-package/
        expect(output).not.toMatch /Dev Packages.*1/
        expect(output).not.toMatch /dev-package@1\.0\.0/
        expect(output).not.toMatch /(empty)/

    it 'displays "empty" for User section', ->
      removeFakePackage 'user', 'user-package'
      listPackages [], ->
        lines = console.log.argsForCall.map((arr) -> arr.join(' '))
        expect(lines[0]).toMatch /Built-in Atom Packages.*1/
        expect(lines[1]).toMatch /test-module@1\.0\.0/
        expect(lines[3]).toMatch /Dev Packages.*1/
        expect(lines[4]).toMatch /dev-package@1\.0\.0/
        expect(lines[6]).toMatch /Community Packages.*0/
        expect(lines[7]).toMatch /(empty)/
        expect(lines[9]).toMatch /Git Packages.*1/
        expect(lines[10]).toMatch /git-package@1\.0\.0/
        expect(lines.join("\n")).not.toContain '.bin' # ensure invalid packages aren't listed
