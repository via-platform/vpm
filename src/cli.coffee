vpm = require './vpm-cli'

process.title = 'vpm'

vpm.run process.argv.slice(2), (error) ->
  process.exitCode = if error? then 1 else 0
