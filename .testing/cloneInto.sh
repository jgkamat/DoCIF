
#!/bin/bash

# A simple script to clone this repo in itself.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

REV=$(git rev-parse HEAD)
URL=$(git config --get remote.origin.url)
SUPERDIR="$(echo "$DIR" | grep -Eo '[.a-zA-Z]+[/]*$')"

cd ..
rm -rf "$SUPERDIR"
git clone "$URL" "$SUPERDIR"
cd "$SUPERDIR"
git checkout "$REV"
