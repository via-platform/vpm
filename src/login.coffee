_ = require 'underscore-plus'
yargs = require 'yargs'
Q = require 'q'
read = require 'read'
open = require 'open'

auth = require './auth'
Command = require './command'

module.exports =
class Login extends Command
  @getTokenOrLogin: (callback) ->
    auth.getToken (error, token) ->
      if error?
        new Login().run({callback, commandArgs: []})
      else
        callback(null, token)

  @commandNames: ['login']

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)

    options.usage """
      Usage: vpm login

      Enter your Via.io API token and save it to the keychain. This token will
      be used to identify you when publishing packages to via.world.
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')
    options.string('token').describe('token', 'via.world API token')

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)
    Q(token: options.argv.token)
      .then(@welcomeMessage)
      .then(@openURL)
      .then(@getToken)
      .then(@saveToken)
      .then (token) -> callback(null, token)
      .catch(callback)

  prompt: (options) ->
    readPromise = Q.denodeify(read)
    readPromise(options)

  welcomeMessage: (state) =>
    return Q(state) if state.token

    welcome = """
      Welcome to Via!

      Before you can publish packages, you'll need an API token.

      Visit your account page on Via.world #{'https://via.world/account'.underline},
      copy the token and paste it below when prompted.

    """
    console.log welcome

    @prompt({prompt: "Press [Enter] to open your account page on Via.io."})

  openURL: (state) ->
    return Q(state) if state.token

    open('https://via.world/account')

  getToken: (state) =>
    return Q(state) if state.token

    @prompt({prompt: 'Token>', edit: true})
      .spread (token) ->
        state.token = token
        Q(state)

  saveToken: ({token}) =>
    throw new Error("Token is required") unless token

    process.stdout.write('Saving token to Keychain ')
    auth.saveToken(token)
    @logSuccess()
    Q(token)
