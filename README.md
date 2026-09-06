# Laptop setup

This repository bootstraps a clean Apple Silicon Mac with the selected command-line tools, shell configuration, Git configuration, Rust and Node toolchains, Neovim environment, and macOS preferences.

## Run

Clone the repository, inspect the scripts, and run:

    ./install.sh

The first run may open the Xcode Command Line Tools installer. When it finishes, run the script again.

The installer may request administrator access when adding Homebrew Bash to /etc/shells. Existing managed dotfiles are renamed with a timestamp before replacement.

## What it configures

- Xcode Command Line Tools and Homebrew
- The curated formula list in the Brewfile
- Homebrew Bash as the login shell
- Sanitized Bash, Git, and Neovim configuration
- Node 24.15.0 through NVM
- Rust toolchains, targets, and standard components through rustup
- Neovim plugins, language servers, and Tree-sitter parsers
- Portable macOS preferences

## Manual applications

See APPS.md after the script finishes.

## Credentials

No credentials belong in this repository. Authenticate GitHub CLI with:

    gh auth login
