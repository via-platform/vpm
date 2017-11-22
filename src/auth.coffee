try
  keytar = require 'keytar'
catch error
  # Gracefully handle keytar failing to load due to missing library on Linux
  if process.platform is 'linux'
    keytar =
      findPassword: -> Promise.reject()
      setPassword: -> Promise.reject()
  else
    throw error

tokenName = 'identity.via.world'

module.exports =
  # Get the via.world API token from the keychain.
  #
  # callback - A function to call with an error as the first argument and a
  #            string token as the second argument.
  getToken: (callback) ->
    keytar.findPassword(tokenName)
      .then (token) ->
        if token
          callback(null, token)
        else
          Promise.reject()
      .catch ->
        if token = process.env.VIA_ACCESS_TOKEN
          callback(null, token)
        else
          callback """
            No via.world API token in keychain
            Run `vpm login` or set the `VIA_ACCESS_TOKEN` environment variable.
          """

  # Save the given token to the keychain.
  #
  # token - A string token to save.
  saveToken: (token) ->
    keytar.setPassword(tokenName, 'identity.via.world', token)
