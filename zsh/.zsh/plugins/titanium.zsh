if builtin command -v titanium > /dev/null; then
  function ti-config () {
    ti config android.sdkPath /usr/local/opt/android-sdk
    if [ -e ~/.Genymobile ]; then
      ti config genymotion.enabled true
      ti config genymotion.home ~/.Genymobile/Genymotion/deployed/
      ti config genymotion.path /opt/homebrew-cask/Caskroom/genymotion/2.3.0/Genymotion.app
      ti config genymotion.executables.genymotion /opt/homebrew-cask/Caskroom/genymotion/2.3.0/Genymotion.app/Contents/MacOS/genymotion
      ti config genymotion.executables.player /opt/homebrew-cask/Caskroom/genymotion/2.3.0/Genymotion.app/Contents/MacOS/player
      ti config genymotion.executables.vboxmanage /usr/bin/VBoxManage
    fi
  }
fi