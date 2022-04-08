#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

set -eu
cd "$DIR" || exit 1

info() {
  printf "\r[ \033[00;34m..\033[0m ] $1\n"
}

success() {
  printf "\r\033[2K[ \033[00;32mOK\033[0m ] $1\n"
}

main() {
  read -p "Set release version: " -r
  echo 
  echo "Building Release Assets"
  swift build -c release --arch arm64
  swift build -c release --arch x86_64
  cp $DIR/.build/arm64-apple-macosx/release/Pinentry-TouchID $DIR/.build/pinentry-touchid-$REPLY-darwin-arm64
  cp $DIR/.build/x86_64-apple-macosx/release/Pinentry-TouchID $DIR/.build/pinentry-touchid-$REPLY-darwin-x86_64
  echo
  echo "Creating release $REPLY"
  echo
  gh release create $REPLY --generate-notes --target main
  echo
  echo "Uploading release assets"
  echo
  gh release upload $REPLY $DIR/.build/pinentry-touchid-$REPLY-darwin-arm64 $DIR/.build/pinentry-touchid-$REPLY-darwin-x86_64
}

main