#!/usr/bin/env bash

# Materialize everything declared by init.lua and lazy-lock.json.

set -euo pipefail

echo "Synchronizing Neovim plugins."
nvim --headless "+Lazy! sync" +qa

echo "Installing Neovim language servers."
nvim --headless \
  "+MasonInstall angular-language-server css-lsp html-lsp lua-language-server pyright rust-analyzer" \
  +qa

echo "Installing and updating Tree-sitter parsers."
nvim --headless "+TSUpdate" +qa

echo "Neovim bootstrap complete."

