child_process = require 'child_process'
fs = require './fs'
path = require 'path'
npm = require 'npm'
semver = require 'semver'

module.exports =
  getHomeDirectory: ->
    if process.platform is 'win32' then process.env.USERPROFILE else process.env.HOME

  getViaDirectory: ->
    process.env.VIA_HOME ? path.join(@getHomeDirectory(), '.via')

  getRustupHomeDirPath: ->
    if process.env.RUSTUP_HOME
      process.env.RUSTUP_HOME
    else
      path.join(@getHomeDirectory(), '.multirust')

  getCacheDirectory: ->
    path.join(@getViaDirectory(), '.vpm')

  getResourcePath: (callback) ->
    if process.env.VIA_RESOURCE_PATH
      return process.nextTick -> callback(process.env.VIA_RESOURCE_PATH)

    vpmFolder = path.resolve(__dirname, '..')
    appFolder = path.dirname(vpmFolder)
    if path.basename(vpmFolder) is 'vpm' and path.basename(appFolder) is 'app'
      asarPath = "#{appFolder}.asar"
      if fs.existsSync(asarPath)
        return process.nextTick -> callback(asarPath)

    vpmFolder = path.resolve(__dirname, '..', '..', '..')
    appFolder = path.dirname(vpmFolder)
    if path.basename(vpmFolder) is 'vpm' and path.basename(appFolder) is 'app'
      asarPath = "#{appFolder}.asar"
      if fs.existsSync(asarPath)
        return process.nextTick -> callback(asarPath)

    switch process.platform
      when 'darwin'
        child_process.exec 'mdfind "kMDItemCFBundleIdentifier == \'com.github.via\'"', (error, stdout='', stderr) ->
          [appLocation] = stdout.split('\n') unless error
          appLocation = '/Applications/Via.app' unless appLocation
          callback("#{appLocation}/Contents/Resources/app.asar")
      when 'linux'
        appLocation = '/usr/local/share/via/resources/app.asar'
        unless fs.existsSync(appLocation)
          appLocation = '/usr/share/via/resources/app.asar'
        process.nextTick -> callback(appLocation)

  getReposDirectory: ->
    process.env.VIA_REPOS_HOME ? path.join(@getHomeDirectory(), 'github')

  getElectronUrl: ->
    process.env.VIA_ELECTRON_URL ? 'https://atom.io/download/electron'

  getViaPackagesUrl: ->
    process.env.VIA_PACKAGES_URL ? "http://localhost:4100" #"https://packages.via.world"

  getViaApiUrl: ->
    process.env.VIA_API_URL ? 'https://via.world/api'

  getElectronArch: ->
    switch process.platform
      when 'darwin' then 'x64'
      else process.env.VIA_ARCH ? process.arch

  getUserConfigPath: ->
    path.resolve(@getViaDirectory(), '.vpmrc')

  getGlobalConfigPath: ->
    path.resolve(@getViaDirectory(), '.vpm', '.vpmrc')

  isWin32: ->
    process.platform is 'win32'

  x86ProgramFilesDirectory: ->
    process.env["ProgramFiles(x86)"] or process.env["ProgramFiles"]

  getInstalledVisualStudioFlag: ->
    return null unless @isWin32()

    # Use the explictly-configured version when set
    return process.env.GYP_MSVS_VERSION if process.env.GYP_MSVS_VERSION

    return '2015' if @visualStudioIsInstalled("14.0")
    return '2013' if @visualStudioIsInstalled("12.0")
    return '2012' if @visualStudioIsInstalled("11.0")
    return '2010' if @visualStudioIsInstalled("10.0")

  visualStudioIsInstalled: (version) ->
    fs.existsSync(path.join(@x86ProgramFilesDirectory(), "Microsoft Visual Studio #{version}", "Common7", "IDE"))

  loadNpm: (callback) ->
    npmOptions =
      userconfig: @getUserConfigPath()
      globalconfig: @getGlobalConfigPath()
    npm.load npmOptions, -> callback(null, npm)

  getSetting: (key, callback) ->
    @loadNpm -> callback(npm.config.get(key))

  setupApmRcFile: ->
    try
      fs.writeFileSync @getGlobalConfigPath(), """
        ; This file is auto-generated and should not be edited since any
        ; modifications will be lost the next time any vpm command is run.
        ;
        ; You should instead edit your .vpmrc config located in ~/.via/.vpmrc
        cache = #{@getCacheDirectory()}
        ; Hide progress-bar to prevent npm from altering vpm console output.
        progress = false
      """
