#!/usr/bin/env bash

# Apply the portable macOS preferences captured from the source laptop.
# Most changes take effect after Dock, Finder, and SystemUIServer restart.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Applying macOS preferences."

# Appearance and input behavior.
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1
defaults write com.apple.universalaccess reduceTransparency -bool true

# Locale and keyboard layout.
defaults write NSGlobalDomain AppleLocale -string "en_US"
defaults write NSGlobalDomain AppleLanguages -array "en-US"

# Dock behavior and hot corners.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

add_dock_app() {
  local app_path="$1"
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://$app_path</string><key>_CFURLStringType</key><integer>15</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
}

defaults write com.apple.dock persistent-apps -array
add_dock_app "/System/Applications/Messages.app"
add_dock_app "/System/Applications/Calendar.app"
add_dock_app "/System/Applications/Notes.app"

defaults write com.apple.dock persistent-others -array \
  "<dict><key>tile-data</key><dict><key>arrangement</key><integer>1</integer><key>displayas</key><integer>1</integer><key>file-data</key><dict><key>_CFURLString</key><string>file://$HOME/Downloads/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>Downloads</string><key>showas</key><integer>1</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"

# Finder.
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder ShowPathbar -bool true

# Screenshots.
mkdir -p "$HOME/Documents/screenshots"
defaults write com.apple.screencapture location -string "$HOME/Documents/screenshots"

# Built-in and Bluetooth trackpads.
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true
  defaults write "$domain" TrackpadRightClick -bool true
  defaults write "$domain" TrackpadScroll -bool true
  defaults write "$domain" TrackpadPinch -bool true
  defaults write "$domain" TrackpadRotate -bool true
  defaults write "$domain" TrackpadThreeFingerDrag -bool false
  defaults write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadThreeFingerVertSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  defaults write "$domain" TrackpadFiveFingerPinchGesture -int 2
done
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true

# Bluetooth mouse.
MOUSE_DOMAIN="com.apple.driver.AppleBluetoothMultitouch.mouse"
defaults write "$MOUSE_DOMAIN" MouseButtonMode -string "TwoButton"
defaults write "$MOUSE_DOMAIN" MouseHorizontalScroll -bool true
defaults write "$MOUSE_DOMAIN" MouseVerticalScroll -bool true
defaults write "$MOUSE_DOMAIN" MouseMomentumScroll -bool true
defaults write "$MOUSE_DOMAIN" MouseOneFingerDoubleTapGesture -int 1
defaults write "$MOUSE_DOMAIN" MouseTwoFingerDoubleTapGesture -int 3
defaults write "$MOUSE_DOMAIN" MouseTwoFingerHorizSwipeGesture -int 2

# Desktop and window management.
defaults write com.apple.WindowManager GloballyEnabled -bool false
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
defaults write com.apple.WindowManager HideDesktop -bool true
defaults write com.apple.WindowManager StandardHideWidgets -bool false
defaults write com.apple.WindowManager StageManagerHideWidgets -bool false
defaults write com.apple.WindowManager AppWindowGroupingBehavior -int 1
defaults write com.apple.WindowManager AutoHide -bool false

# Clock and menu-bar visibility.
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -bool false
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
for item in Battery Bluetooth Sound WiFi Clock BentoBox-0; do
  defaults write com.apple.controlcenter "NSStatusItem VisibleCC $item" -bool true
done

# Preserve the captured keyboard shortcut map.
defaults import com.apple.symbolichotkeys \
  "$REPO_DIR/dotfiles/macos/com.apple.symbolichotkeys.plist"

# Activity Monitor.
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 102

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS preferences applied."
