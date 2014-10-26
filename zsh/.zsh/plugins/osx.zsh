export DEVELOPER_DIR="/Applications/XCode.app/Contents/Developer"

alias symbolicatecrash="/Applications/Xcode.app/Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash"

function brew_cask_upgrade() {
  for c in `brew cask list`; do
    ! brew cask info $c | grep -qF "Not installed" || brew cask install $c
  done
}
