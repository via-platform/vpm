path = require 'path'
async = require 'async'
Command = require './command'
config = require './config'
fs = require './fs'

module.exports =
class RebuildModuleCache extends Command
  @commandNames: ['rebuild-module-cache']

  constructor: ->
    @atomPackagesDirectory = path.join(config.getAtomDirectory(), 'packages')

  getResourcePath: (callback) ->
    if @resourcePath
      process.nextTick => callback(@resourcePath)
    else
      config.getResourcePath (@resourcePath) => callback(@resourcePath)

  rebuild: (packageDirectory, callback) ->
    @getResourcePath (resourcePath) =>
      try
        @moduleCache ?= require(path.join(resourcePath, 'src', 'module-cache'))
        @moduleCache.create(packageDirectory)
      catch error
        return callback(error)

      callback()

  run: (options) ->
    {callback} = options

    commands = []
    fs.list(@atomPackagesDirectory).forEach (packageName) =>
      packageDirectory = path.join(@atomPackagesDirectory, packageName)
      return if fs.isSymbolicLinkSync(packageDirectory)
      return unless fs.isDirectorySync(packageDirectory)

      commands.push (callback) =>
        process.stdout.write "Rebuilding #{packageName} module cache "
        @rebuild packageDirectory, (error) =>
          if error?
            @logFailure()
          else
            @logSuccess()
          callback(error)

    async.waterfall(commands, callback)