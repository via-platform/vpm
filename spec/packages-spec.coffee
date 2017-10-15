Packages = require '../lib/packages'

describe 'getRemote', ->
  it 'returns origin if remote could not be determined', ->
    expect(Packages.getRemote()).toEqual('origin')

  it 'returns repository.url', ->
    pack =
      repository:
        type: 'git'
        url: 'https://github.com/via/vpm.git'
    expect(Packages.getRemote(pack)).toEqual(pack.repository.url)

  it 'returns repository', ->
    pack =
      repository: 'https://github.com/via/vpm'
    expect(Packages.getRemote(pack)).toEqual(pack.repository)
