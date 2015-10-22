export DEVELOPER_DIR="/Applications/XCode.app/Contents/Developer"

alias symbolicatecrash="/Applications/Xcode.app/Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash"

function brew-cask-upgrade() {
  for c in `brew cask list`; do
    if brew cask info $c | grep -qF "Not Installed"; then
      echo c
      #brew cask uninstall $c
      #brew cask install $c
    fi
  done
}
