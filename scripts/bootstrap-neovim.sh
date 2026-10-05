#!/usr/bin/env bash

# Materialize everything declared by init.lua and lazy-lock.json.

set -euo pipefail

# Work around a Command Line Tools bug: clang/ld default to the newest SDK on
# disk, which can be a pre-release one (e.g. MacOSX27.sdk) whose .tbd files use
# an arch-variant syntax the installed linker can't parse yet, producing
# "ld: tapi error: malformed file ... unknown architecture". Pin SDKROOT to the
# stable SDK (the `MacOSX.sdk` symlink) so native builds (Tree-sitter parsers,
# blink.cmp's fuzzy matcher) link correctly.
STABLE_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
if [[ -d "$STABLE_SDK" ]]; then
  export SDKROOT="$STABLE_SDK"
fi

echo "Synchronizing Neovim plugins."
nvim --headless "+Lazy! sync" +qa

echo "Installing Neovim language servers."
nvim --headless \
  "+MasonInstall angular-language-server css-lsp html-lsp lua-language-server pyright rust-analyzer" \
  +qa

echo "Installing and updating Tree-sitter parsers."
nvim --headless "+TSUpdate" +qa

echo "Neovim bootstrap complete."

