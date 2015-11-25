#!/bin/bash

# Script for testing docif

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure our submodules are up to scratch.
cd "$DIR"
git submodule update --init

# Get the sha of the current rev
cd "$DIR/.."
DOCIF_REV="$(git rev-parse HEAD)"

# Update our submodule to that rev
cd "$DIR/DoCIF"
git fetch origin
git checkout "$DOCIF_REV"

# Get back to the testing dir
cd "$DIR"


