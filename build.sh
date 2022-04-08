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
    info "Building"
    swift build -c release
    cp -f .build/release/Pinentry-TouchID $HOME/.local/bin/pinentry-touchid
    success "Build complete!"
}

main