path = require 'path'
_ = require 'underscore-plus'
yargs = require 'yargs'
vpm = require './vpm'
Command = require './command'

module.exports =
class Config extends Command
  @commandNames: ['config']

  constructor: ->
    viaDirectory = vpm.getAtomDirectory()
    @viaNodeDirectory = path.join(viaDirectory, '.node-gyp')
    @viaNpmPath = require.resolve('npm/bin/npm-cli')

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: vpm config set <key> <value>
             vpm config get <key>
             vpm config delete <key>
             vpm config list
             vpm config edit

    """
    options.alias('h', 'help').describe('help', 'Print this usage message')

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)

    configArgs = ['--globalconfig', vpm.getGlobalConfigPath(), '--userconfig', vpm.getUserConfigPath(), 'config']
    configArgs = configArgs.concat(options.argv._)

    env = _.extend({}, process.env, {HOME: @viaNodeDirectory, RUSTUP_HOME: vpm.getRustupHomeDirPath()})
    configOptions = {env}

    @fork @viaNpmPath, configArgs, configOptions, (code, stderr='', stdout='') ->
      if code is 0
        process.stdout.write(stdout) if stdout
        callback()
      else
        process.stdout.write(stderr) if stderr
        callback(new Error("npm config failed: #{code}"))
