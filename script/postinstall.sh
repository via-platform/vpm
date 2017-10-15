#!/bin/bash

set -e

echo ">> Downloading bundled Node"
node script/download-node.js

echo
echo ">> Rebuilding vpm dependencies with bundled Node $(./bin/node -p "process.version + ' ' + process.arch")"
./bin/npm rebuild

echo
echo ">> Deduping vpm dependencies"
./bin/npm dedupe
