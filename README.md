# vpm - Via Package Manager

[![Linux Build Status](https://travis-ci.org/via/vpm.svg?branch=master)](https://travis-ci.org/via/vpm)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/j6ixw374a397ugkb/branch/master?svg=true)](https://ci.appveyor.com/project/Via/vpm/branch/master)
[![Dependency Status](https://david-dm.org/via/vpm.svg)](https://david-dm.org/via/vpm)

Discover and install Via packages powered by [via.world](https://via.world)

You can configure vpm by using the `vpm config` command line option (recommended) or by manually editing the `~/.via/.vpmrc` file as per the [npm config](https://docs.npmjs.com/misc/config).

## Relation to npm

vpm bundles [npm](https://github.com/npm/npm) with it and spawns `npm` processes to install Via packages. The major difference is that `vpm` sets multiple command line arguments to `npm` to ensure that native modules are built against Chromium's v8 headers instead of node's v8 headers.

The other major difference is that Via packages are installed to `~/.via/packages` instead of a local `node_modules` folder and Via packages are published to and installed from GitHub repositories instead of [npmjs.com](https://www.npmjs.com/)

Therefore you can think of `vpm` as a simple `npm` wrapper that builds on top of the many strengths of `npm` but is customized and optimized to be used for Via packages.

## Installing

`vpm` is bundled and installed automatically with Via. You can run the _Via > Install Shell Commands_ menu option to install it again if you aren't able to run it from a terminal (macOS only).

## Building

  * Clone the repository
  * :penguin: Install `libsecret-1-dev` (or the relevant `libsecret` development dependency) if you are on Linux
  * Run `npm install`; this will install the dependencies with your built-in version of Node/npm, and then rebuild them with the bundled versions.
  * Run `./bin/npm run build` to compile the CoffeeScript code (or `.\bin\npm.cmd run build` on Windows)
  * Run `./bin/npm test` to run the specs (or `.\bin\npm.cmd test` on Windows)

### Why `bin/npm` / `bin\npm.cmd`?

`vpm` includes `npm`, and spawns it for various processes. It also comes with a bundled version of Node, and this script ensures that npm uses the right version of Node for things like running the tests. If you're using the same version of Node as is listed in `BUNDLED_NODE_VERSION`, you can skip using this script.

## Using

Run `vpm help` to see all the supported commands and `vpm help <command>` to
learn more about a specific command.

The common commands are `vpm install <package_name>` to install a new package,
`vpm featured` to see all the featured packages, and `vpm publish` to publish
a package to [via.world](https://via.world).

## Behind a firewall?

If you are behind a firewall and seeing SSL errors when installing packages
you can disable strict SSL by running:

```
vpm config set strict-ssl false
```

## Using a proxy?

If you are using a HTTP(S) proxy you can configure `vpm` to use it by running:

```
vpm config set https-proxy https://9.0.2.1:0
```

You can run `vpm config get https-proxy` to verify it has been set correctly.

## Viewing configuration

You can also run `vpm config list` to see all the custom config settings.
