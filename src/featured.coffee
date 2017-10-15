_ = require 'underscore-plus'
yargs = require 'yargs'

Command = require './command'
config = require './vpm'
request = require './request'
tree = require './tree'

module.exports =
class Featured extends Command
  @commandNames: ['featured']

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: vpm featured
             vpm featured --themes
             vpm featured --compatible 0.49.0

      List the Via packages and themes that are currently featured in the
      via.world registry.
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')
    options.alias('t', 'themes').boolean('themes').describe('themes', 'Only list themes')
    options.alias('c', 'compatible').string('compatible').describe('compatible', 'Only list packages/themes compatible with this Via version')
    options.boolean('json').describe('json', 'Output featured packages as JSON array')

  getFeaturedPackagesByType: (viaVersion, packageType, callback) ->
    [callback, viaVersion] = [viaVersion, null] if _.isFunction(viaVersion)

    requestSettings =
      url: "#{config.getViaApiUrl()}/#{packageType}/featured"
      json: true
    requestSettings.qs = engine: viaVersion if viaVersion

    request.get requestSettings, (error, response, body=[]) ->
      if error?
        callback(error)
      else if response.statusCode is 200
        packages = body.filter (pack) -> pack?.releases?.latest?
        packages = packages.map ({readme, metadata, downloads, stargazers_count}) -> _.extend({}, metadata, {readme, downloads, stargazers_count})
        packages = _.sortBy(packages, 'name')
        callback(null, packages)
      else
        message = request.getErrorMessage(response, body)
        callback("Requesting packages failed: #{message}")

  getAllFeaturedPackages: (viaVersion, callback) ->
    @getFeaturedPackagesByType viaVersion, 'packages', (error, packages) =>
      return callback(error) if error?

      @getFeaturedPackagesByType viaVersion, 'themes', (error, themes) ->
        return callback(error) if error?
        callback(null, packages.concat(themes))

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)

    listCallback = (error, packages) ->
      return callback(error) if error?

      if options.argv.json
        console.log(JSON.stringify(packages))
      else
        if options.argv.themes
          console.log "#{'Featured Via Themes'.cyan} (#{packages.length})"
        else
          console.log "#{'Featured Via Packages'.cyan} (#{packages.length})"

        tree packages, ({name, version, description, downloads, stargazers_count}) ->
          label = name.yellow
          label += " #{description.replace(/\s+/g, ' ')}" if description
          label += " (#{_.pluralize(downloads, 'download')}, #{_.pluralize(stargazers_count, 'star')})".grey if downloads >= 0 and stargazers_count >= 0
          label

        console.log()
        console.log "Use `vpm install` to install them or visit #{'https://packages.via.world'.underline} to read more about them."
        console.log()

      callback()

    if options.argv.themes
      @getFeaturedPackagesByType(options.argv.compatible, 'themes', listCallback)
    else
      @getAllFeaturedPackages(options.argv.compatible, listCallback)
