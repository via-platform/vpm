_ = require 'underscore-plus'
yargs = require 'yargs'

Command = require './command'
config = require './vpm'
request = require './request'
tree = require './tree'
{isDeprecatedPackage} = require './deprecated-packages'

module.exports =
class Search extends Command
  @commandNames: ['search']

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)
    options.usage """

      Usage: vpm search <package_name>

      Search for Via packages/themes on the via.world registry.
    """
    options.alias('h', 'help').describe('help', 'Print this usage message')
    options.boolean('json').describe('json', 'Output matching packages as JSON array')
    options.boolean('packages').describe('packages', 'Search only non-theme packages').alias('p', 'packages')
    options.boolean('themes').describe('themes', 'Search only themes').alias('t', 'themes')

  searchPackages: (query, opts, callback) ->
    qs =
      q: query

    if opts.packages
      qs.filter = 'package'
    else if opts.themes
      qs.filter = 'theme'

    requestSettings =
      url: "#{config.getViaPackagesUrl()}/search"
      qs: qs
      json: true

    request.get requestSettings, (error, response, body={}) ->
      if error?
        callback(error)
      else if response.statusCode is 200
        callback(null, body)
      else
        message = request.getErrorMessage(response, body)
        callback("Searching packages failed: #{message}")

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)
    [query] = options.argv._

    unless query
      callback("Missing required search query")
      return

    searchOptions =
      packages: options.argv.packages
      themes: options.argv.themes

    @searchPackages query, searchOptions, (error, packages) ->
      if error?
        callback(error)
        return

      if options.argv.json
        console.log(JSON.stringify(packages))
      else
        heading = "Search Results For '#{query}'".cyan
        console.log "#{heading} (#{packages.length})"

        tree packages, ({name, version, description, downloads, stargazers_count}) ->
          label = name.yellow
          label += " #{description.replace(/\s+/g, ' ')}" if description
          label += " (#{_.pluralize(downloads, 'download')}, #{_.pluralize(stargazers_count, 'star')})".grey if downloads >= 0 and stargazers_count >= 0
          label

        console.log()
        console.log "Use `vpm install` to install them or visit #{'https://packages.via.world'.underline} to read more about them."
        console.log()

      callback()
