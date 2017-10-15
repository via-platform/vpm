path = require 'path'
async = require 'async'
yargs = require 'yargs'
Command = require './command'
config = require './vpm'
fs = require './fs'

module.exports =
class RebuildModuleCache extends Command
  @commandNames: ['rebuild-module-cache']

  constructor: ->
    @viaPackagesDirectory = path.join(config.getAtomDirectory(), 'packages')

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: vpm rebuild-module-cache

      Rebuild the module cache for all the packages installed to
      ~/.via/packages

      You can see the state of the module cache for a package by looking
      at the _viaModuleCache property in the package's package.json file.

      This command skips all linked packages.
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')

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
    fs.list(@viaPackagesDirectory).forEach (packageName) =>
      packageDirectory = path.join(@viaPackagesDirectory, packageName)
      return if fs.isSymbolicLinkSync(packageDirectory)
      return unless fs.isFileSync(path.join(packageDirectory, 'package.json'))

      commands.push (callback) =>
        process.stdout.write "Rebuilding #{packageName} module cache "
        @rebuild packageDirectory, (error) =>
          if error?
            @logFailure()
          else
            @logSuccess()
          callback(error)

    async.waterfall(commands, callback)
