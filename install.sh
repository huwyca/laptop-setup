#!/usr/bin/env bash

# Bootstrap a clean Apple Silicon Mac from this repository.
# The script is safe to rerun: existing dotfiles are backed up before replacement,
# and package managers skip software that is already installed.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX="pre-laptop-setup-$(date +%Y%m%d%H%M%S)"
NODE_VERSION="24.15.0"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setup supports macOS only." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This setup currently targets Apple Silicon Macs." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Requesting installation of Xcode Command Line Tools."
  xcode-select --install
  echo "Finish the installer, then run this script again."
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ANALYTICS=1

echo "Installing Homebrew formulae."
brew bundle --file="$REPO_DIR/Brewfile"

install_file() {
  local source_path="$1"
  local destination_path="$2"

  mkdir -p "$(dirname "$destination_path")"

  if [[ -e "$destination_path" ]] && ! cmp -s "$source_path" "$destination_path"; then
    mv "$destination_path" "$destination_path.$BACKUP_SUFFIX"
    echo "Backed up $destination_path"
  fi

  cp "$source_path" "$destination_path"
}

echo "Installing shell and developer configuration."
install_file "$REPO_DIR/dotfiles/bashrc" "$HOME/.bashrc"
install_file "$REPO_DIR/dotfiles/bash_profile" "$HOME/.bash_profile"
install_file "$REPO_DIR/dotfiles/gitconfig" "$HOME/.gitconfig"
install_file "$REPO_DIR/dotfiles/git/ignore" "$HOME/.config/git/ignore"
install_file "$REPO_DIR/dotfiles/nvim/init.lua" "$HOME/.config/nvim/init.lua"
install_file "$REPO_DIR/dotfiles/nvim/init_old.lua" "$HOME/.config/nvim/init_old.lua"
install_file "$REPO_DIR/dotfiles/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"

BREW_BASH="/opt/homebrew/bin/bash"
if ! grep -Fxq "$BREW_BASH" /etc/shells; then
  echo "Adding Homebrew Bash to /etc/shells (sudo required)."
  echo "$BREW_BASH" | sudo tee -a /etc/shells >/dev/null
fi

CURRENT_SHELL="$(dscacheutil -q user -a name "$USER" | awk '/^shell:/{print $2}')"
if [[ "$CURRENT_SHELL" != "$BREW_BASH" ]]; then
  echo "Changing the login shell to Homebrew Bash."
  chsh -s "$BREW_BASH"
fi

export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
# shellcheck source=/dev/null
source "/opt/homebrew/opt/nvm/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
nvm use "$NODE_VERSION"

if ! command -v rustup >/dev/null 2>&1; then
  echo "Installing rustup."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --default-toolchain stable
fi

# shellcheck source=/dev/null
source "$HOME/.cargo/env"
rustup toolchain install stable
rustup toolchain install 1.94.1
rustup toolchain install 1.97.1
rustup default stable
rustup target add aarch64-apple-darwin x86_64-apple-darwin
rustup component add clippy llvm-tools-preview rust-docs rustfmt

"$REPO_DIR/scripts/bootstrap-neovim.sh"
"$REPO_DIR/scripts/macos-settings.sh"

echo
echo "Setup complete."
echo "Authenticate GitHub CLI with: gh auth login"
echo "Review the manual application checklist at: $REPO_DIR/APPS.md"
echo "Open a new terminal to use Homebrew Bash."
